Set shell = CreateObject("WScript.Shell")
scriptPath = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
command = "powershell -ExecutionPolicy Bypass -File """ & scriptPath & "\deploy-prod.ps1"""
If WScript.Arguments.Count > 0 Then
  For i = 0 To WScript.Arguments.Count - 1
    command = command & " " & WScript.Arguments(i)
  Next
End If
shell.Run command, 1, True
