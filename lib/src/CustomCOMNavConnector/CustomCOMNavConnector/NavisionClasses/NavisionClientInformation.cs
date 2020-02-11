namespace CustomCOMNavConnector.NavisionClasses
{
    public class NavisionClientInformation
    {
        public string ServerName { get; set; }
        public string DatabaseName { get; set; }
        public string CompanyName { get; set; }
        public object ObjectDesigner { get; set; }
        public object Application { get; set; }

        public ServerType ServerType { get; set; }
        public float Version { get; set; }
        public int WindowHandle { get; set; }
        public int ProcessID { get; set; }
        public string ExecutionPath { get; set; }
        public string ExecutionFileName { get; set; }
        public int MajorVersion { get; set; }

        public override string ToString()
        {
            return $"[ServerName={ServerName}, DatabaseName={DatabaseName}, CompanyName={CompanyName}, " +
                $"ServerType=={ServerType}, Version={Version}, WindowHandle={WindowHandle}, ProcessID={ProcessID}, " +
                $"ExecutionPath=\"{ExecutionPath}\", ExecutionFileName=\"{ExecutionFileName}\", MajorVersion={MajorVersion}]";
        }

    }
}
