'----------------------------------------------------------
'             *** Directory Housekeeping ***
'              Created 2016 by Chris Kramer
'            for American Spirit Corporation
'==========================================================
dim oFS, oFolders, oFiles, Folders, Files, Depth, Hour, Limits
set oFS = CreateObject("Scripting.FileSystemObject")
set Folders = CreateObject("Scripting.Dictionary")
set Files = CreateObject("Scripting.Dictionary")
set Limits = CreateObject("Scripting.Dictionary")


MakeRounds 1 'oclock (hour during which it is okay to purge)


'----------------------------------------------------------
  sub LoadFolders(sFolder)
'==========================================================
  dim aFolder

  if oFS.FileExists(sFolder) then
    set oFolders = oFS.OpenTextFile(sFolder)

    do until oFolders.AtEndOfStream
      aFolder = split(oFolders.ReadLine,vbTab)
      if ubound(aFolder) > 0 then Folders(aFolder(0)) = aFolder(1)
    loop

    oFolders.Close
  end if
end sub


'----------------------------------------------------------
  sub LoadFiles(sFile)
'==========================================================
  dim aFile

  if oFS.FileExists(sFile) then
    set oFiles = oFS.OpenTextFile(sFile)

    do until oFiles.AtEndOfStream
      aFile = split(oFiles.ReadLine,vbTab)
      if ubound(aFile) > 0 then Files(aFile(0)) = aFile(1)
    loop

    oFiles.Close
  end if
end sub



'----------------------------------------------------------
  function Deunicode(sUnicode)
'==========================================================
  dim aUnicode, sASCII, i

  aUnicode = split(Escape(sUnicode),"%u")

  if ubound(aUnicode) > 0 then
    sASCII = aUnicode(0)
    for i = 1 to ubound(aUnicode)
      if len(aUnicode(i)) >= 4 then sASCII = sASCII & right(aUnicode(i),len(aUnicode(i)) - 4)
    next
  else
    sASCII = sUnicode
  end if

  Deunicode = sASCII
end function



'----------------------------------------------------------
  sub Log(sMessage)
'==========================================================
  dim oLog, sPath
  sPath = oFS.GetParentFolderName(WScript.ScriptFullName)
  set oLog = oFS.OpenTextFile(sPath & "\events.log",8,true,0)
  oLog.WriteLine now & vbTab & sMessage
  oLog.close
end sub



'----------------------------------------------------------
  sub Process(sPath)
'==========================================================
  dim oFolder, oFile, sFile

  set oFolder = oFS.GetFolder(sPath)

  if oFolder.Files.Count = 0 and oFolder.SubFolders.Count = 0 and ubound(split(sPath,"\")) > Depth + 2 then
    if Folders.Exists(sPath) then
      if (DatePart("h",now) = Hour and cInt(Folders(sPath)) > cInt(Limits("folders"))) then
        on error resume next
        oFolder.Delete
        if Err.Number <> 0 then
          Log "Error " & Err.Number & " removing " & sPath & "; " & Err.Description
          Err.Clear
        else
          Log "Removed " & sPath & " (" & Folders(sPath) & ")"
        end if
        on error goto 0
      end if
      if oFS.FolderExists(sPath) then oFolders.WriteLine sPath & vbTab & Folders(sPath) + 1
    else
      oFolders.WriteLine sPath & vbTab & "1"
    end if
  else
    for each oFile in oFolder.Files
      sFile = oFile.Path
      if left(oFile.Name,1) <> "." and not (oFile.Attributes and 2) then
        if sFile = Deunicode(sFile) then
          if Files.Exists(sFile) then
            if (DatePart("h",now) = Hour and cInt(Files(sFile)) > cInt(Limits("files"))) then
              on error resume next
              oFile.Delete
              if Err.Number <> 0 then
                Log "Error " & Err.Number & " removing " & sFile & "; " & Err.Description
                Err.Clear
              else
                Log "Removed " & sFile & " (" & Files(sFile) & ")"
              end if
              on error goto 0
            end if
            if oFS.FileExists(sFile) then oFiles.WriteLine sFile & vbTab & Files(sFile) + 1
          else
            oFiles.WriteLine sFile & vbTab & "1"
          end if
        end if
      end if
    next
    for each oFolder in oFolder.SubFolders
      if left(oFolder.Name,1) <> "." and not (oFolder.Attributes and 2) then
        if oFolder.Path = Deunicode(oFolder.Path) then Process oFolder.Path
      end if
    next
  end if
end sub


'----------------------------------------------------------
  sub SetLimits(sServer)
'==========================================================
  dim aLimits, aLimit, sLimit

  Limits("folders") = 5
  Limits("files") = 5

  if oFS.FileExists(sServer & "\retention.txt") then
    aLimits = split(oFS.OpenTextFile(sServer & "\retention.txt").ReadAll,vbCrLf)

    for each sLimit in aLimits
      aLimit = split(lcase(sLimit),":")
      if (ubound(aLimit) > 0 and Limits.Exists(aLimit(0))) and isnumeric(aLimit(1)) then Limits(aLimit(0)) = aLimit(1)
    next
  end if
end sub

'----------------------------------------------------------
  sub Clean(sServer)
'==========================================================
  dim oPath, sPath
    
  if oFS.FileExists(sServer & "\path.txt") then
    sPath = oFS.OpenTextFile(sServer & "\path.txt").ReadLine
    LoadFolders sServer & "\folders.txt"
    LoadFiles sServer & "\files.txt"

    set oFolders = oFS.CreateTextFile(sServer & "\folders.txt",true,false)
    set oFiles = oFS.CreateTextFile(sServer & "\files.txt",true,false)

    if oFS.FolderExists(sPath) then
      set oPath = oFS.GetFolder(sPath)
      Depth = ubound(split(oPath.Path,"\"))
      for each oFolder in oPath.SubFolders
        Process oFolder.Path
      next
    end if

    oFolders.Close
    oFiles.Close
  end if
end sub


'----------------------------------------------------------
  sub MakeRounds(iHour)
'==========================================================
  dim oServer
  Hour = iHour

  for each oServer in oFS.GetFolder(".\").SubFolders
    SetLimits(oServer.Path)
    Clean(oServer.Path)
  next
end sub
