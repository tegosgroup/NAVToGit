using System;
using System.Collections.Generic;

namespace CustomCOMNavConnector.NavisionClasses
{
    public class Program
    {

        public static void Main(String[] args)
        {
            CompileNavObjectsCmdlet cmdlet = new CompileNavObjectsCmdlet();
            cmdlet.DatabaseName = @"Demo Database NAV (6-0)";
            List<string> l = new List<string>();
            l.Add(@"codeunit\codeunit 000021.txt");
            cmdlet.SelectedObjectsList = l;
            cmdlet.Execute();
        }

    }
}
