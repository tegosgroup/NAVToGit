using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.IO;
using System.Text.RegularExpressions;

namespace CustomCOMNavConnector.NavisionClasses
{
    [Cmdlet(VerbsCommon.Get, "NavisionObjects")]
    public class GetNavisionClients : PSCmdlet
    {
        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            Position = 0
        )]
        public string DatabaseName { get; set; }

        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            Position = 1
        )]
        public string TempFolder { get; set; }

        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            Position = 2
        )]
        public string ObjectType { get; set; }

        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            Position = 3
        )]
        public string ObjectFilter { get; set; }

        [Parameter(
            Mandatory = false,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            Position = 4
        )]
        public string Log { get; set; }

        protected override void ProcessRecord()
        {
            WriteObject(ExecuteCmdLet());
        }

        private int ExecuteCmdLet()
        {
            try
            {
                List<NavisionClientInformation> navisionClientInformationList = NavConnector.CheckRot();
                NavConnector navConnector = null;
                if (navisionClientInformationList.Count == 0)
                {
                    return -1;
                }

                foreach (NavisionClientInformation navInfo in navisionClientInformationList)
                {
                    if (navInfo.DatabaseName.Equals(DatabaseName, StringComparison.InvariantCultureIgnoreCase))
                    {
                        navConnector = new NavConnector(navInfo);
                        break;
                    }
                }
                if(navConnector != null)
                {
                    string path = Path.Combine(TempFolder, ObjectType.ToLower());
                    Directory.CreateDirectory(path);

                    if(String.IsNullOrEmpty(ObjectFilter))
                    {
                        throw new Exception("ObjectFilter null.");
                    }
                    string temp = navConnector.GetAllObjectText(NavObjectTypeClass.GetObjectTypeByString(ObjectType), GetObjectFilter());
                    path = Path.Combine(path, "Export.txt");
                    File.WriteAllText(path, temp);
                    return 1;
                }
                return -1;
            }
            catch (Exception e)
            {
                throw e;
            }
        }

        private string GetObjectFilter()
        {
            string pattern = @"([^=\;\s]*)\s*=\s*([^\;]*)";
            string filter = $"WHERE(Type=CONST({NavObjectTypeClass.GetObjectTypeByString(ObjectType)}),";
            foreach (Match match in Regex.Matches(ObjectFilter, pattern, RegexOptions.IgnoreCase))
                filter = filter + match.Groups[1].Value + "=FILTER(" + match.Groups[2].Value + "),";
            filter = filter.Substring(0, filter.Length - 1) + ")";
            return filter;
           //return $"WHERE(Type=CONST({NavObjectTypeClass.GetObjectTypeByString(ObjectType)}),ID=FILTER({ObjectFilter}))";
        }
                                                                                         

        private void LogMessage(string toLog)
        {
            try
            {
                if (!string.IsNullOrEmpty(toLog))
                {
                    File.AppendAllText(Log, toLog + "\n");
                }
            }
            catch { }
        }

        private void LogException(Exception e)
        {
            LogMessage(e.ToString());
        }



    }
}
