using System;
using System.Reflection;

namespace CustomCOMNavConnector.NavisionClasses
{
    public enum NavObjectType
    {
        [StringValue("All")]
        All = 0,
        [StringValue("Table")]
        Table = 1,
        [StringValue("Form")]
        Form = 2,
        [StringValue("Report")]
        Report = 3,
        [StringValue("Dataport")]
        Dataport = 4,
        [StringValue("Codeunit")]
        Codeunit = 5,
        [StringValue("XMLport")]
        XMLport = 6,
        [StringValue("MenuSuite")]
        MenuSuite = 7,
        [StringValue("Page")]
        Page = 8,
        [StringValue("Query")]
        Query = 9,
        [StringValue("Record")]
        Record = 20,
        [StringValue("Unknown")]
        Unknown = -1
    }

    public static class NavObjectTypeClass
    {
        public static NavObjectType GetObjectTypeByString(string line)
        {

            if (line.ToUpper() == NavObjectType.Codeunit.GetStringValue().ToUpper())
                return NavObjectType.Codeunit;
            if (line.ToUpper() == NavObjectType.Form.GetStringValue().ToUpper())
                return NavObjectType.Form;
            if (line.ToUpper() == NavObjectType.Dataport.GetStringValue().ToUpper())
                return NavObjectType.Dataport;
            if (line.ToUpper() == NavObjectType.MenuSuite.GetStringValue().ToUpper())
                return NavObjectType.MenuSuite;
            if (line.ToUpper() == NavObjectType.Report.GetStringValue().ToUpper())
                return NavObjectType.Report;
            if (line.ToUpper() == NavObjectType.Table.GetStringValue().ToUpper())
                return NavObjectType.Table;
            if (line.ToUpper() == NavObjectType.XMLport.GetStringValue().ToUpper())
                return NavObjectType.XMLport;
            if (line.ToUpper() == NavObjectType.Query.GetStringValue().ToUpper())
                return NavObjectType.Query;
            if (line.ToUpper() == NavObjectType.Page.GetStringValue().ToUpper())
                return NavObjectType.Page;
            if (line.ToUpper() == NavObjectType.Record.GetStringValue().ToUpper())
                return NavObjectType.Table;

            return NavObjectType.Unknown;
        }
    }

    internal class StringValueAttribute : Attribute
    {

        public string StringValue { get; private set; }

        public StringValueAttribute(string value)
        {
            StringValue = value;
        }

    }

    public static class EnumOverides
    {
        public static string GetStringValue(this Enum value)
        {
            Type type = value.GetType();
            FieldInfo fieldInfo = type.GetField(value.ToString());

            StringValueAttribute[] attribs = fieldInfo.GetCustomAttributes(
                typeof(StringValueAttribute), false) as StringValueAttribute[];

            return attribs?.Length > 0 ? attribs[0].StringValue : null;
        }
    }

}
