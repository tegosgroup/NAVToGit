using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;

namespace CustomCOMNavConnector.NavisionClasses
{
    public static class RunningObjectTable
    {

        [DllImport("ole32.dll")]
        private static extern int GetRunningObjectTable(uint reserved, out IRunningObjectTable pprot);

        [DllImport("ole32.dll")]
        private static extern int CreateBindCtx(uint reserved, out IBindCtx pctx);

        public static List<RunningNavObject> GetRunningCOMObjectsByName(string objectDisplayName, string objectDisplayNameCheck2)
        {
            IRunningObjectTable runningObjectTable = null;
            List<RunningNavObject> runningNavObjectList = new List<RunningNavObject>();
            IEnumMoniker monikerList = null;

            try
            {
                if (GetRunningObjectTable(0, out runningObjectTable) != 0 || runningObjectTable == null) return null;

                runningObjectTable.EnumRunning(out monikerList);
                monikerList.Reset();
                IMoniker[] monikerContainer = new IMoniker[1];

                IntPtr pointerFetchedMonikers = IntPtr.Zero;
                while (monikerList.Next(1, monikerContainer, pointerFetchedMonikers) == 0)
                {
                    IBindCtx bindInfo;
                    string displayName;
                    CreateBindCtx(0, out bindInfo);

                    try
                    {
                        monikerContainer[0].GetDisplayName(bindInfo, null, out displayName);
                        Marshal.ReleaseComObject(bindInfo);
                    }
                    catch (Exception)
                    {
                        Marshal.ReleaseComObject(bindInfo);
                        continue;
                    }

                    if (displayName.IndexOf(objectDisplayName, StringComparison.Ordinal) == -1) continue;
                    if (displayName.IndexOf(objectDisplayNameCheck2, StringComparison.Ordinal) != -1 ||
                        (displayName.IndexOf("servername=", StringComparison.Ordinal) != -1 && displayName.IndexOf("database=", StringComparison.Ordinal) != -1))
                    {
                        object comInstance;
                        runningObjectTable.GetObject(monikerContainer[0], out comInstance);
                        if (comInstance == null) continue;
                        RunningNavObject navObject = new RunningNavObject(displayName, comInstance);

                        string[] split = displayName.ToLower().Split(new[] { "?" }, StringSplitOptions.RemoveEmptyEntries);
                        string[] split2 = split[1].Split(new[] { "&" }, StringSplitOptions.RemoveEmptyEntries);
                        if (split2.Length >= 1)
                            navObject.Servername = split2[0].Replace("servername=", string.Empty);
                        if (split2.Length >= 2)
                            navObject.Database = split2[1].Replace("database=", string.Empty);
                        if (split2.Length >= 3)
                            navObject.Company = split2[2].Replace("company=", string.Empty);

                        if (!string.IsNullOrEmpty(navObject.Company)) continue;

                        runningNavObjectList.Add(navObject);
                    }
                }

                return runningNavObjectList;
            }
            catch (TimeoutException e)
            {
                throw new TimeoutException(e.ToString());
            }
            finally
            {
                if (runningObjectTable != null) Marshal.ReleaseComObject(runningObjectTable);
                if (monikerList != null) Marshal.ReleaseComObject(monikerList);
            }
        }

    }
}
