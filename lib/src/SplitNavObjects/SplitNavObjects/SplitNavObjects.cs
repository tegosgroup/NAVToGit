using System;
using System.Text;
using System.IO;
using System.Management.Automation;
using System.Text.RegularExpressions;

namespace SplitNavObjects
{
    [Cmdlet(VerbsCommon.Split, "NavObjectFile")]
    public class SplitNavObjects : PSCmdlet
    {
        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            Position = 0,
            HelpMessage = "Not stated"
        )]
        public string Path { get; set; }

        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            Position = 1,
            HelpMessage = "Not stated"
        )]
        public string Type { get; set; }

        [Parameter(
            Mandatory = false,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            Position = 2,
            HelpMessage = "Not stated"
        )]
        public string Log { get; set; }

        protected override void ProcessRecord()
        {
            LogMessage("Start der Funktion!!");
            try
            {
                string actualObjName, fileName;
                if (Type.Equals("Record", StringComparison.CurrentCultureIgnoreCase))
                {
                    actualObjName = "Table";
                    fileName = "Record";
                }
                else
                {
                    actualObjName = Type;
                    fileName = Type;
                }
                string file = System.IO.Path.Combine(Path, Type);
                file = System.IO.Path.Combine(file, "Export.txt");
                if (File.Exists(file))
                {
                    string pattern = @"^OBJECT " + actualObjName + " ";

                    Encoding enc = Encoding.GetEncoding(850);
                    string readStr = File.ReadAllText(file, enc);
                    string[] objects = Regex.Split(readStr, pattern, RegexOptions.Multiline | RegexOptions.Compiled);
                    long id;
                    string filepath;
                    byte[] content;
                    FileStream stream;
                    foreach (string o in objects)
                    {
                        if (o != "" && o != pattern)
                        {
                            content = enc.GetBytes($"OBJECT {actualObjName} " + o);
                            long.TryParse(o.Substring(0, o.IndexOf(" ")), out id);
                            filepath = System.IO.Path.Combine(Path, $"{Type}/{Type} {id.ToString("0000000000")}.txt");
                            LogMessage($"Filepath: {filepath}");
                            stream = new FileStream(filepath, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None);
                            stream.SetLength(0); //Delete all data
                            stream.Write(content, 0, content.Length); //Write Data
                            stream.Flush();
                            stream.Close();
                        }
                    }
                    File.Delete(file);
                }
                else
                {
                    LogMessage($"Export file for type {Type} was not found.");
                }
            }
            catch (Exception e)
            {
                LogException(e);
            }
        }

        private void LogMessage(string toLog)
        {
            if (!String.IsNullOrEmpty(toLog))
            {
                try
                {
                    File.AppendAllText(Path, toLog + "\n");
                }
                catch{}
            }
        }

        private void LogException(Exception e)
        {
            LogMessage(e.ToString());
        }

    }
}
