using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.Collections;
using System.Text.RegularExpressions;

namespace CustomCOMNavConnector.NavisionClasses
{
    [Cmdlet(VerbsCommon.Set, "Nav6ObjectsCompiled")]
    public class CompileNavObjectsCmdlet : Cmdlet
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
        public List<string> SelectedObjectsList { get; set; }

        public List<string> ErrorObjects { get; set; } = new List<string>();

        public void Execute()
        {
            ProcessRecord();
        }

        protected override void ProcessRecord()
        {
            try
            {
                List<NavisionClientInformation> navisionClientInformationList = NavConnector.CheckRot();
                NavConnector navConnector = null;
                if (navisionClientInformationList.Count == 0)
                {
                    return;
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
                    Regex regex = new Regex(@"([^\\]*).*\s([0-9]*).txt");
                    int type, id;
                    foreach (string o in SelectedObjectsList)
                    {
                        MatchCollection collection = regex.Matches(o);
                        if(collection.Count > 0)
                        {
                            Match match = regex.Matches(o)[0];

                            type = (int)(NavObjectTypeClass.GetObjectTypeByString(match.Groups[1].Value));
                            int.TryParse(match.Groups[2].Value, out id);
                            if (navConnector.CompileObject(type, id) != 0)
                            {
                                ErrorObjects.Add(o);
                            }
                        }
                    }
                }
            }
            catch(Exception e)
            {
                WriteObject(e);
                return;
            }
            WriteObject(ErrorObjects);
        }


    }
}
