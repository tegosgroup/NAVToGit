using System;
using System.Collections.Generic;
using System.Management.Automation;

namespace CustomCOMNavConnector.NavisionClasses
{
    [Cmdlet(VerbsCommon.Find, "NavisionProcess")]
    public class FindProcessCmdlet : Cmdlet
    {

        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            Position = 0,
            HelpMessage = "Database name, whose data should be retrieved"
        )]
        public string DatabaseName { get; set; }

        protected override void ProcessRecord()
        {
            WriteObject(ExecuteCmdLet());
        }

        private int ExecuteCmdLet()
        {
            try
            {
                List<NavisionClientInformation> navisionClientInformationList = NavConnector.CheckRot();
                if (navisionClientInformationList.Count > 0)
                {
                    foreach (NavisionClientInformation navInfo in navisionClientInformationList)
                    {
                        if (navInfo.DatabaseName.Equals(DatabaseName, StringComparison.InvariantCultureIgnoreCase))
                        {
                            return 0;
                        }
                    }
                }
            }
            catch { }
            return -1;
        }

    }
}
