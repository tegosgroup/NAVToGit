using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Management.Automation;

namespace CustomCOMNavConnector.NavisionClasses
{
    [Cmdlet(VerbsCommon.Set, "NavisionObjectText")]
    public class ImportObjectFromTextCmdlet : Cmdlet
    {

        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            Position = 0,
            HelpMessage = "Database name, whose data should be retrieved"
        )]
        public string DatabaseName { get; set; }

        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            Position = 1,
            HelpMessage = "Database name, whose data should be retrieved"
        )]
        public string FilePath { get; set; }

        protected override void ProcessRecord()
        {
            WriteObject(ExecuteCmdLet());
        }

        private int ExecuteCmdLet()
        {
            try
            {
                List<NavisionClientInformation> list = NavConnector.CheckRot();
                if (list.Count > 0)
                {
                    NavConnector navConnector = null;
                    foreach (NavisionClientInformation navInfo in list)
                    {
                        if (navInfo.DatabaseName.Equals(DatabaseName, StringComparison.InvariantCultureIgnoreCase))
                        {
                            navConnector = new NavConnector(navInfo);
                            break;
                        }
                    }
                    if(navConnector != null)
                    {
                        FileStream fs = new FileStream(FilePath, FileMode.Open);
                        byte[] buffer = new byte[fs.Length];
                        fs.Read(buffer, 0, (int)fs.Length);
                        fs.Close();
                        string fileContent = Encoding.GetEncoding(850).GetString(buffer);
                        navConnector.SetObjectText(fileContent);
                        return 0;
                    }
                }
            }
            catch (Exception e)
            {
            }
            return -1;
        }

    }
}
