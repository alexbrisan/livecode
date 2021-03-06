﻿script "StandaloneInclusions"
/*
Copyright (C) 2016 LiveCode Ltd.

This file is part of LiveCode.

LiveCode is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License v3 as published by the Free
Software Foundation.

LiveCode is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License
along with LiveCode.  If not see <http://www.gnu.org/licenses/>.  */

local sSupportStack
on TestSetup   
   start using stack "revSBLibrary"
		
   set the itemdelimiter to slash
   local tSupportStack
   put the filename of me into tSupportStack
   put "_support.livecodescript" into item -1 of tSupportStack
   put tSupportStack into sSupportStack
   start using stack sSupportStack
end TestSetup

on TestTeardown
   StandaloneBuilderCleanUpStandalones
   stop using stack sSupportStack
end TestTeardown

private function _TestScriptForInclusion pWhich
   set the itemdelimiter to slash
   local tExternalTest
   put the filename of me into tExternalTest
   put "/externals/" & pWhich & ".livecodescript" into item -1 of tExternalTest
   return textDecode(url("binfile:" & tExternalTest), "utf-8")
end _TestScriptForInclusion

on TestStandaloneInclusions
   local tDir
   set the itemdelimiter to slash
   set the defaultfolder to item 1 to -2 of the filename of me
   
   put "_TestSavingStandalone" into tDir
   
   create folder tDir
   
   local tStackName, tStackID
   create stack
   put it into tStackID
   put the short name of tStackID into tStackName
   
   local tStackFilename
   put the folder & "/" & tDir & "/stack.livecode" into tStackFilename
   set the filename of tStackID to tStackFilename
   
   set the itemdelimiter to comma
   repeat for each item tItem in "xml,security,zip,sqlite"
      _TestStandaloneWithInclusion tStackId, tStackFilename, tItem
   end repeat
   
   revDeleteFolder tDir
end TestStandaloneInclusions

private command _TestStandaloneWithInclusion pStackId, pStackFilename, pItem
   local tScript
   put _TestScriptForInclusion(pItem) into tScript
   
   set the script of pStackId to tScript
   revIDESaveStack pStackId
   	 
   local tExecutablePath
   _TestBuildStandalone pStackFilename, tExecutablePath
   if the result is not empty then
      TestAssert "building standalone", false
      exit _TestStandaloneWithInclusion
   end if
   
   TestAssert "building standalone", true
   
   local tStackName
   put the short name of pStackId into tStackName
    
   TestDiagnostic "location" && tExecutablePath
   
   TestAssert "standalone in expected location", there is a file tExecutablePath
   
   local tResult, tShellCmd
   put quote & tExecutablePath & quote into tShellCmd
   if the environment contains "command line" then
      put " -ui" after tShellCmd
   end if
   get shell(tShellCmd)
   put the result into tResult
   
   if tResult is not empty then
      TestDiagnostic "standalone quit with" && tResult & ":" && it
   end if
      
   TestAssert "standalone with" && pItem && "inclusion startup", \
         tResult is empty
end _TestStandaloneWithInclusion

private command _TestBuildStandalone pStackPath, @xStandalonePath
	local tStackName, tResult
	put the short name of stack pStackPath into tStackName
	
	TestDiagnostic "Building standalone -" && pStackPath
	
	StandaloneBuilderSaveAsStandalone tStackName, xStandalonePath
	return the result
end _TestBuildStandalone
