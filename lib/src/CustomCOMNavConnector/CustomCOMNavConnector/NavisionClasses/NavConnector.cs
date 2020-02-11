using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Security;
using System.Text;
using System.Threading.Tasks;

namespace CustomCOMNavConnector.NavisionClasses
{
    public class NavConnector
    {

        #region Private Constants

        private const int NavisionEncoding = 850;
        private const string DEFAULTMONIKERNAME = "!C/SIDE";
        private const string COMPANYCHECKFORNAVISIONCLIENT = "company=";

        #endregion

        #region Public Datafields

        public NavisionClientInformation NavClientInformation { get; private set; }
        private INSObjectDesigner _objectDesigner;

        #endregion

        #region Constructor

        public NavConnector(NavisionClientInformation client)
        {
            SetActiveNavisionClient(client);
        }

        #endregion

        #region Public Member

        public int CompileObject(int navObjectType, int objectId)
        {
           return _objectDesigner.CompileObject(navObjectType, objectId);
        }

        public bool SetActiveNavisionClient(NavisionClientInformation navisionClientInformation)
        {
            if (navisionClientInformation == null) return false;

            NavClientInformation = navisionClientInformation;
            _objectDesigner = NavClientInformation.ObjectDesigner as INSObjectDesigner;

            return true;
        }

        public static List<NavisionClientInformation> CheckRot()
        {
            List<NavisionClientInformation> navisionClientsTemp = new List<NavisionClientInformation>();
            bool isTimeout = true;

            List<RunningNavObject> runningNavObjects = null;
            Task t2 = new Task(
                    () =>
                    {
                        runningNavObjects = RunningObjectTable.GetRunningCOMObjectsByName(DEFAULTMONIKERNAME, COMPANYCHECKFORNAVISIONCLIENT);
                        isTimeout = false;
                    });
            runningNavObjects = RunningObjectTable.GetRunningCOMObjectsByName(DEFAULTMONIKERNAME, COMPANYCHECKFORNAVISIONCLIENT);
            t2.WithTimeout(new TimeSpan(0, 0, 5));
            t2.Start();
            t2.Wait(5500);
            if (isTimeout)
                throw new TimeoutException("Timeout");

            if (!runningNavObjects.Any())
            {
                return navisionClientsTemp;
            }

            foreach (RunningNavObject de in runningNavObjects)
            {
                RunningNavObject de1 = de;

                Task t = new Task(
                    () =>
                    {
                        INSObjectDesigner navObjectDesigner = de1.ComInstance as INSObjectDesigner;
                        INSHyperlink hyperlink = de1.ComInstance as INSHyperlink;
                        INSApplication application = de1.ComInstance as INSApplication;

                        if (navObjectDesigner == null) return;



                        NavisionClientInformation nci = new NavisionClientInformation();

                        try
                        {
                            navObjectDesigner.GetDatabaseName(out string value);
                            if (value != null)
                                nci.DatabaseName = Encoding.GetEncoding(NavisionEncoding).GetString(Encoding.Default.GetBytes(value));

                            navObjectDesigner.GetCompanyName(out value);
                            if (value != null)
                                nci.CompanyName = Encoding.GetEncoding(NavisionEncoding).GetString(Encoding.Default.GetBytes(value));

                            navObjectDesigner.GetServerName(out value);
                            if (value != null)
                                nci.ServerName = Encoding.GetEncoding(NavisionEncoding).GetString(Encoding.Default.GetBytes(value));

                            navObjectDesigner.GetServerType(out int value2);

                            nci.ServerType = (ServerType)value2;

                            nci.ObjectDesigner = navObjectDesigner;
                            nci.Application = application;

                            try
                            {
                                navObjectDesigner.GetCSIDEVersion(out string version);
                                string[] str = version.Split(new[] { " " }, StringSplitOptions.None);
                                nci.Version = float.Parse(str[1], CultureInfo.InvariantCulture);
                            }
                            catch
                            {
                            }


                            hyperlink.GetNavWindowHandle(out int handle);
                            nci.WindowHandle = handle;

                            GetWindowThreadProcessId((IntPtr)handle, out uint processID);
                            nci.ProcessID = (int)processID;

                            nci.ExecutionPath = Path.GetDirectoryName(GetProcessPath(new IntPtr(handle)));
                            nci.ExecutionFileName = GetProcessPath(new IntPtr(handle));
                            FileVersionInfo myFileVersionInfo = FileVersionInfo.GetVersionInfo(nci.ExecutionFileName);
                            nci.MajorVersion = myFileVersionInfo.FileMajorPart;
                        }
                        catch
                        {
                            navisionClientsTemp = null;
                            throw new Exception("Communication Problem");
                        }

                        if (navisionClientsTemp == null)
                        {
                            isTimeout = false;
                            return;
                        }

                        if (navisionClientsTemp.Any(
                            info =>
                            info.ServerName == nci.ServerName &&
                            info.DatabaseName == nci.DatabaseName))
                        {
                            navisionClientsTemp = null;
                            throw new Exception("Multiple Clients");
                        }

                        navisionClientsTemp.Add(nci);
                        isTimeout = false;
                    });
                t.WithTimeout(new TimeSpan(0, 0, 2));
                t.Start();
                t.Wait(2500);
            }

            if (isTimeout)
                throw new Exception("Timeout");

            return navisionClientsTemp;
        }

        public int SetObjectText(string completeObjectText)
        {
            byte[] byteArray = Encoding.GetEncoding(NavisionEncoding).GetBytes(completeObjectText);
            MemoryStream memStream = new MemoryStream();
            memStream.Write(byteArray, 0, byteArray.Length);
            memStream.Seek(0, SeekOrigin.Begin);

            return WriteObjectsFromStream(memStream);
        }

        public int WriteObjectsFromStream(Stream stream)
        {
            if (NavClientInformation == null) throw new Exception("Connection lost.");
            IStream source = ToIStream(stream);
            int result = _objectDesigner.WriteObjects(source);
            ProcessResult(result);
            return result;
        }



        public string GetAllObjectText(NavObjectType navObjectType, string filter)
        {
            MemoryStream memStream = ReadObjectToStream(filter);
            memStream.Seek(0, SeekOrigin.Begin);
            byte[] buffer = new byte[memStream.Length];
            memStream.Read(buffer, 0, buffer.Length);


            string objectText = Encoding.GetEncoding(NavisionEncoding).GetString(buffer);

            return CheckTextValid(objectText, navObjectType);
        }

        #endregion

        #region Private Members

        private static unsafe IStream ToIStream(Stream stream)
        {
            byte[] buffer = new byte[stream.Length];
            stream.Read(buffer, 0, buffer.Length);
            uint num = 0;
            IntPtr pcbWritten = new IntPtr(&num);
            CreateStreamOnHGlobal(0, true, out IStream pOutStm);
            pOutStm.Write(buffer, buffer.Length, pcbWritten);
            pOutStm.Seek(0, 0, IntPtr.Zero);
            return pOutStm;
        }

        private static string CheckTextValid(string objectText, NavObjectType navObjectType)
        {
            string returnString = objectText.IndexOfAny(new[] { '\0', '\t', '\b' }) != -1 ? null : objectText;
            if (returnString != null) return returnString;
            if (navObjectType != NavObjectType.Report) return null;

            int beginIndex = objectText.IndexOf("  RDLDATA\r\n  {", StringComparison.OrdinalIgnoreCase);
            if (beginIndex == -1) return null;
            if (objectText.IndexOfAny(new[] { '\0', '\t', '\b' }, 0, beginIndex) != -1) return null;
            int endIndex = objectText.IndexOf("    END_OF_RDLDATA\r\n  }", beginIndex, StringComparison.OrdinalIgnoreCase);
            if (endIndex == -1) return null;
            if (objectText.IndexOfAny(new[] { '\0', '\t', '\b' }, endIndex, objectText.Length - endIndex) != -1) return null;

            return objectText;
        }

        private MemoryStream ReadObjectToStream(string filter)
        {
            CreateStreamOnHGlobal(0, true, out IStream pOutStm);

            //int result = _objectDesigner.ReadObject(navObjectType, objectId, pOutStm);
            int result = _objectDesigner.ReadObjects(filter, pOutStm);   
            ProcessResult(result);
            return ToMemoryStream(pOutStm);
        }

        private static unsafe MemoryStream ToMemoryStream(IStream comStream)
        {
            MemoryStream stream = new MemoryStream();
            byte[] pv = new byte[100];
            uint num = 0;
            IntPtr pcbRead = new IntPtr(&num);
            comStream.Seek(0, 0, IntPtr.Zero);
            do
            {
                num = 0;
                comStream.Read(pv, pv.Length, pcbRead);
                stream.Write(pv, 0, (int)num);
            }
            // ReSharper disable LoopVariableIsNeverChangedInsideLoop
            while (num > 0);
            // ReSharper restore LoopVariableIsNeverChangedInsideLoop
            return stream;
        }

        private void ProcessResult(int result)
        {
            if (result != 0)
            {
                GetErrorInfo(0, out IErrorInfo ppIErrorInfo);
                string pBstrDescription = string.Empty;
                ppIErrorInfo?.GetDescription(out pBstrDescription);
                string message = string.Format(CultureInfo.CurrentCulture, "Method returned an error. HRESULT = 0x{0:X8}", result);
                if (pBstrDescription != string.Empty)
                {
                    message = pBstrDescription;
                    //message = message + " : " + pBstrDescription;
                }
                throw new Exception(message);
            }
        }

        private static string GetProcessPath(IntPtr hwnd)
        {
            try
            {
                User32.GetWindowThreadProcessId(hwnd, out uint pid);
                Process proc = Process.GetProcessById((int)pid);
                return proc.MainModule.FileName;
            }
            catch (Exception ex) { return ex.Message; }
        }

        #endregion

        #region Dllimports

        [DllImport("user32.dll")]
        private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

        [DllImport("OLE32.DLL")]
        private static extern int CreateStreamOnHGlobal(int hGlobalMemHandle, bool fDeleteOnRelease, out IStream pOutStm);

        [DllImport("oleaut32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetErrorInfo(int dwReserved,
            [MarshalAs(UnmanagedType.Interface)] out IErrorInfo ppIErrorInfo);
        [ComImport, SuppressUnmanagedCodeSecurity, Guid("1CF2B120-547D-101B-8E65-08002B2BD119"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]

        #endregion

        #region IErrorInfo Interface
        private interface IErrorInfo
        {
            [PreserveSig]
            int GetGUID();
            [PreserveSig]
            int GetSource([MarshalAs(UnmanagedType.BStr)] out string pBstrSource);
            [PreserveSig]
            int GetDescription([MarshalAs(UnmanagedType.BStr)] out string pBstrDescription);
        }
        #endregion

    }
}
