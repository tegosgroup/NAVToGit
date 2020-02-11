namespace CustomCOMNavConnector.NavisionClasses
{
    public class RunningNavObject
    {
        public readonly object ComInstance;
        public string DisplayName;
        public string Servername;
        public string Database;
        public string Company;

        public RunningNavObject(string displayName, object comInstance)
        {
            ComInstance = comInstance;
            DisplayName = displayName;
        }
    }
}
