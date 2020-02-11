using System;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;

namespace CustomCOMNavConnector.NavisionClasses
{
    [ComImport, Guid("50000004-0000-1000-0001-0000836BD2D2"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface INSObjectDesigner
    {
        [PreserveSig]
        int ReadObject([In] int objectType, [In] int objectId, [In] IStream destination);
        [PreserveSig]
        int ReadObjects([In] String filter, [In] IStream destination);
        [PreserveSig]
        int WriteObjects([In] IStream source);
        [PreserveSig]
        int CompileObject([In] int objectType, [In] int objectId);
        [PreserveSig]
        int CompileObjects([In] String filter);
        [PreserveSig]
        int GetServerName(out String serverName);
        [PreserveSig]
        int GetDatabaseName(out String databaseName);  // gets database folder and name
        [PreserveSig]
        int GetServerType(out int serverType);   // 1=SQL, 2=Classic
        [PreserveSig]
        int GetCSIDEVersion(out String csideVersion);  // "DE 5.0 SP1", "DE 6.00", etc.
        [PreserveSig]
        int GetApplicationVersion(out String applicationVersion);  // "DE Dynamics NAV 5.0 SP1", "DE Dynamics NAV 6.0", etc.
        [PreserveSig]
        int GetCompanyName(out String companyName);
    }

    [ComImport, Guid("50000004-0000-1000-0011-0000836BD2D2"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface INSCallbackEnum
    {
        [PreserveSig]
        int NextRecord([In, MarshalAs(UnmanagedType.Interface)] INSRec record);
        [PreserveSig]
        int NextFieldValue([In] int fieldNo, [In] string fieldValue, [In] string dataType);
        [PreserveSig]
        int NextFilterValue([In] int fieldNo, [In] string filterValue);
        [PreserveSig]
        int NextTable([In] int tableNo, [In] string tableName);
        [PreserveSig]
        int NextFieldDef([In] int fieldNo, [In] string fieldName, [In] string fieldCaption, [In] string dataType, [In] int dataLength, [In] int f);
    }

    [ComImport, Guid("50000004-0000-1000-0007-0000836BD2D2"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface INSRec
    {
        [PreserveSig]
        int SetFieldValue([In] int fieldNo, [In] String value, [In] bool validate);
        [PreserveSig]
        int GetFieldValue([In] int fieldNo, out String value);
        [PreserveSig]
        int EnumFieldValues([In, MarshalAs(UnmanagedType.Interface)] INSCallbackEnum callback);
    }

    [ComImport, Guid("50000004-0000-1000-0006-0000836BD2D2"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface INSTable
    {
        [PreserveSig]
        int Delete([In, MarshalAs(UnmanagedType.Interface)] INSRec rec);
        [PreserveSig]
        int Insert([In, MarshalAs(UnmanagedType.Interface)] INSRec rec);
        [PreserveSig]
        int Modify([In, MarshalAs(UnmanagedType.Interface)] INSRec rec);
        [PreserveSig]
        int Init([Out, MarshalAs(UnmanagedType.Interface)] out INSRec rec);
        [PreserveSig]
        int SetFilter([In] int fieldNo, [In] string filterValue);
        [PreserveSig]
        int EnumFilters([In, MarshalAs(UnmanagedType.Interface)] INSCallbackEnum callback);
        [PreserveSig]
        int EnumRecords([In, MarshalAs(UnmanagedType.Interface)] INSCallbackEnum callback);
        [PreserveSig]
        int EnumFields([In, MarshalAs(UnmanagedType.Interface)] INSCallbackEnum callback, [In] int languageI);
        [PreserveSig]
        int Find([In, MarshalAs(UnmanagedType.Interface)] INSRec rec);
        [PreserveSig]
        int GetID(out int tableId);
        [PreserveSig]
        int proc13(out int a);
    }

    [ComImport, Guid("50000004-0000-1000-0010-0000836BD2D2"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface INSAppBase
    {
        [PreserveSig]
        int GetTable([In] int a, [Out, MarshalAs(UnmanagedType.Interface)] out INSTable table);
        [PreserveSig]
        int GetInfos(out string servername, out string databasename, out string company, out string username);
        [PreserveSig]
        int StartTrans(); //start the write transaction in the client
        [PreserveSig]
        int EndTransaction([In] bool commitChanges);
        [PreserveSig]
        int Error([In] string message);  //Display error in client, roll back the transaction
        [PreserveSig]
        int EnumTables([In, MarshalAs(UnmanagedType.Interface)] INSCallbackEnum a, [In] int flag); //meaning of flag is not known for me yet
    }

    [ComImport, Guid("50000004-0000-1000-0005-0000836BD2D2"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface INSHook
    {
        [PreserveSig]
        int proc3([In, MarshalAs(UnmanagedType.Interface)] INSAppBase appBase);
    }

    [ComImport, Guid("50000004-0000-1000-0009-0000836BD2D2"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface INSMenuButtonEvents
    {
        [PreserveSig]
        int proc3();
        [PreserveSig]
        int proc4([In] int a);
    }

    [ComImport, Guid("50000004-0000-1000-0004-0000836BD2D2"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface INSApplicationEvents
    {
        [PreserveSig]
        int OnFormOpen([In, MarshalAs(UnmanagedType.Interface)] INSForm form);
        [PreserveSig]
        int Proc4([In, MarshalAs(UnmanagedType.Interface)] INSForm form, [In] String b);
        [PreserveSig]
        int OnActiveChanged([In] bool active); //when the client get/lost focus
        [PreserveSig]
        int OnCompanyClose(); //when company/db is closed/re-opened
    }

    [ComImport, Guid("50000004-0000-1000-0000-0000836BD2D2"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface INSHyperlink
    {
        [PreserveSig]
        int Open([In] string link);
        [PreserveSig]
        int GetNavWindowHandle(out int handle);
    }

    [ComImport, Guid("50000004-0000-1000-0008-0000836BD2D2"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface INSMenuButton
    {
        [PreserveSig]
        int proc3([In] string a);
        [PreserveSig]
        int proc4([In] int a, [In] string b, [In] string c);
    }

    [ComImport, Guid("50000004-0000-1000-0003-0000836BD2D2"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface INSForm
    {
        [PreserveSig]
        int GetHyperlink(out String hyperlink);        // gets Hyperlink with Fieldcaptions
        [PreserveSig]
        int GetID(out String formId);               // gets active object's type (Form) and ID
        [PreserveSig]
        int GetRec([Out, MarshalAs(UnmanagedType.Interface)] out INSRec record);
        [PreserveSig]
        int GetTable([Out, MarshalAs(UnmanagedType.Interface)] out INSTable table);
        [PreserveSig]
        int GetLanguageID(out int languageID);          // gets Language ID of application (1033, etc.)
        [PreserveSig]
        int GetButton([Out, MarshalAs(UnmanagedType.Interface)] out INSMenuButton menuButton); //never succeeded to call it correctly, each time end with error in NAV client...
        [PreserveSig]
        int proc9();
    }

    [ComImport, Guid("50000004-0000-1000-0002-0000836BD2D2"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface INSApplication
    {
        [PreserveSig]
        int GetCurrentForm([Out, MarshalAs(UnmanagedType.Interface)] out INSForm form);
    }
}
