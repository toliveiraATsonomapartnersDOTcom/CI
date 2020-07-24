package com.EY.GitDiffGenerator;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Objects;

import static java.lang.String.format;

public class Main {

    private static String APP_DIRECTORY = "force-app";

    //this script requires a command line argument
    public static void main(String[] args) {
        //terminate if no arguments passed; will cause an out of bounds error otherwise
        if(args.length == 0){
            System.out.println("Command line argument required; args[0] should be a branch path; OPTIONAL app directory can be included afterward");
            System.exit(0);
        }

        String BRANCH = args[0];
        if(args.length > 1){
            APP_DIRECTORY = args[1];
        }

        var regexMapper = new Regex();
        var diffCommandResponse = CommandOutput(format("git diff %s --name-status", BRANCH));
        var diffActions = GetDiffActionsList(diffCommandResponse, regexMapper);

        var deploymentDirectory = SetUpDirectory("ReleaseDeploy");
        var deployForceApp = SetUpDirectory(format("%s/%s", deploymentDirectory, "force-app"));
        var deployMain= SetUpDirectory(format("%s/%s", deployForceApp, "main"));
        SetUpDirectory(format("%s/%s", deployMain, "default"));
        var removalDirectory = SetUpDirectory("ReleaseRemove");

        diffActions.forEach((action, actionEntries) ->
        {
            switch (action) {
                case "A", "M" -> ProcessAddModify(actionEntries, deploymentDirectory, removalDirectory, regexMapper);
                case "D" -> ProcessDeletes(actionEntries, removalDirectory, regexMapper);
                default -> ProcessOtherAction(action, actionEntries, deploymentDirectory, removalDirectory, regexMapper);
            }
        });
    }

    private static void ProcessOtherAction(String action, HashMap<String, String> list, String deploymentDirectory, String removalDirectory, Regex regexMapper)
    {
        if(action.startsWith("R")) {
            list.forEach((type, file) -> {
                var files = file.split(APP_DIRECTORY, 2);
                var firstFile = format("%s/%s", APP_DIRECTORY, files[0].replace('/', '\\')).trim();
                var secondFile = format("%s/%s", APP_DIRECTORY, files[1].replace('/', '\\')).trim();

                var firstFileInfo = new File(firstFile);
                var secondFileInfo = new File(secondFile);

                try {
                    if (firstFileInfo.exists()) {
                        HandleAddModify(type, firstFile, firstFileInfo, deploymentDirectory, regexMapper);
                    } else {
                        HandleDelete(type, firstFile, removalDirectory, regexMapper);
                    }

                    if (secondFileInfo.exists()) {
                        HandleAddModify(type, secondFile, secondFileInfo, deploymentDirectory, regexMapper);
                    } else {
                        HandleDelete(type, secondFile, removalDirectory, regexMapper);
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            });
        }
    }

    private static void ProcessDeletes(HashMap<String, String> list, String destinationDirectory, Regex regexMapper)
    {
        list.forEach((type, file) -> {
            try {
                HandleDelete(type, file, destinationDirectory, regexMapper);
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
    }

    private static void HandleDelete(String type, String file, String destinationDirectory, Regex regexMapper) throws IOException {
        var destinationFile = new File(format("%s/%s", destinationDirectory, file.replace('/', '\\')));
        var destinationPath = new File(destinationFile.getAbsolutePath().substring(0, destinationFile.getAbsolutePath().lastIndexOf('\\')));
        if (!destinationPath.exists())
        {
            destinationPath.mkdir();
        }

        if (regexMapper.SPECIAL_HANDLING.contains(type))
        {
            CreateSpecialHandlingDeletedFile(destinationFile.getAbsoluteFile());
        }
        else
        {
            CreateStandardDeletedFile(type, destinationFile.getAbsolutePath());
        }
    }

    private static void CreateSpecialHandlingDeletedFile(File file) throws IOException {
        file.createNewFile();
    }

    private static void CreateStandardDeletedFile(String type, String file) {
        var docNS = "http://soap.sforce.com/2006/04/metadata";
        var factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(true);

        var transformerFactory = TransformerFactory.newInstance();

        try {
            var loader = factory.newDocumentBuilder();
            var document = loader.newDocument();
            var element = document.createElementNS(docNS, type);

            document.appendChild(element);
            element.setAttribute("xmlns", docNS);

            var transformer = transformerFactory.newTransformer();
            transformer.setOutputProperty(OutputKeys.INDENT, "yes");
            DOMSource source = new DOMSource(document);

            var fileStream = new StreamResult(new File(file));
            transformer.transform(source, fileStream);

        } catch (ParserConfigurationException | TransformerException e) {
            e.printStackTrace();

        }
    }

    private static void ProcessAddModify(HashMap<String, String> list, String destinationDirectory, String removalDirectory, Regex regexMapper)
    {
        list.forEach((type, file) -> {
            var fileName = file.replace('/', '\\');
            var fileToCheck = new File(fileName);
            try {
                if (fileToCheck.exists())
                {
                    HandleAddModify(type, fileName, fileToCheck, destinationDirectory, regexMapper);
                }
                else
                {                
                    HandleDelete(type, file, removalDirectory, regexMapper);                
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
    }

    private static void HandleAddModify(String type, String file, File existingFile, String destinationDirectory, Regex regexMapper) throws IOException {
        var destinationFile = new File(format("%s/%s", destinationDirectory, file.replace('/', '\\')));
        var destinationPath = new File(destinationFile.getAbsolutePath().substring(0, destinationFile.getAbsolutePath().lastIndexOf('\\')));
        if (!destinationPath.exists())
        {
            destinationPath.mkdir();
        }

        if (type.equals("LWC") || type.equals("Aura"))
        {
            CopyAllDirectoryContents(existingFile, destinationPath.getAbsolutePath());
            return;
        }

        copyFile(existingFile, destinationDirectory);

        if (regexMapper.SPECIAL_HANDLING.contains(type) && !file.endsWith("-meta.xml"))
        {
            String correspondingMetaXml;

            if(file.matches(regexMapper.METADATA_PATTERNS.get("Documents"))) {
                var fileStub = file.substring(0, file.lastIndexOf('.'));
                correspondingMetaXml = format("%s.document-meta.xml", fileStub);
            } else if(file.matches(regexMapper.METADATA_PATTERNS.get("StaticResources"))) {
                var fileStub = file.substring(0, file.lastIndexOf('.'));
                correspondingMetaXml = format("%s.resource-meta.xml", fileStub);
            } else {
                correspondingMetaXml = format("%s-meta.xml", file);
            }

            var metaXmlFile = new File(correspondingMetaXml);
            if(metaXmlFile.exists()) {
                var destinationMetaXml = new File(format("%s/%s", destinationDirectory, correspondingMetaXml));
                Files.copy(metaXmlFile.toPath(), destinationMetaXml.toPath(), StandardCopyOption.REPLACE_EXISTING);
            }
        }
    }

    private static void CopyAllDirectoryContents(File existingFile, String destinationPath) throws IOException {
        var sourceDirectory = existingFile.getParentFile();
        var files = sourceDirectory.listFiles();

        for(var i = 0; i < Objects.requireNonNull(files).length; i++)
        {
            if (files[i].isDirectory()){
                continue;
            }
            copyFile(files[i], destinationPath);
        }
    }

    private static void copyFile(File toCopy, String destinationPath) throws IOException {
        var directory = new File(destinationPath);
        if (!directory.exists()){
            directory.mkdir();
        }
        var destinationFile = new File(format("%s/%s", destinationPath, toCopy.getName()));
        Files.copy(Paths.get(toCopy.getAbsolutePath()), Paths.get(destinationFile.getAbsolutePath()), StandardCopyOption.REPLACE_EXISTING);
    }

    private static String SetUpDirectory(String directoryName)
    {
        var directory = new File(directoryName);
        if(directory.exists()) {
            directory.delete();
        }
        directory.mkdir();

        return directory.getAbsolutePath();
    }

    private static Hashtable<String, HashMap<String, String>> GetDiffActionsList(String actionsList, Regex regexMapper) {
        var diffActions = new Hashtable<String, HashMap<String, String>>();

        var lines = actionsList.split(System.lineSeparator());


        for (String line : lines) {
            var split = line.split("[ \t]", 2);
            var action = split[0];
            var file = split[1];

            if (!diffActions.containsKey(action)) {
                diffActions.put(action, new HashMap<>());
            }

            regexMapper.METADATA_PATTERNS.forEach((key, value) -> {
                if (file.matches(value)) {
                    diffActions.get(action).put(key, file);
                }
            });
        }

        return diffActions;
    }

    private static String CommandOutput(String command)
    {
        try
        {
            Process process = Runtime.getRuntime().exec(command);
            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream()));
            StringBuilder builder = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                builder.append(line).append(System.lineSeparator());
            }

            reader.close();

            return builder.toString();
        }
        catch (Exception objException)
        {
            return "Error in command: {command}, {objException.Message}";
        }
    }
}