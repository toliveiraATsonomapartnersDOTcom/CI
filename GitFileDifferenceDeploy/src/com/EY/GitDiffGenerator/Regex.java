package com.EY.GitDiffGenerator;

import java.util.Hashtable;
import java.util.List;

public class Regex {
    public List<String> SPECIAL_HANDLING = List.of(
            "Aura", "ApexClass", "ContentAssets", "Email", "LWC", "Trigger", "Documents", "StaticResources"
    );

    public Hashtable<String, String> METADATA_PATTERNS = new Hashtable<>();

    public Regex() {
        METADATA_PATTERNS.put("CustomApplication", "force-app(\\s*.*)applications(\\s*.*)app-meta.xml");
        METADATA_PATTERNS.put("ApprovalProcess", "force-app(\\s*.*)approvalProcesses(\\s*.*)approvalProcess-meta.xml");
        METADATA_PATTERNS.put("AssignmentRules", "force-app(\\s*.*)assignmentRules(\\s*.*)assignmentRules-meta.xml");
        METADATA_PATTERNS.put("Aura", "force-app(\\s*.*)aura(\\s*.*)");
        METADATA_PATTERNS.put("AutoResponseRules", "force-app(\\s*.*)autoResponseRules(\\s*.*)autoResponseRules-meta.xml");
        METADATA_PATTERNS.put("BrandingSet", "force-app(\\s*.*)brandingSets(\\s*.*)brandingSet-meta.xml");
        METADATA_PATTERNS.put("PlatformCachePartition", "force-app(\\s*.*)cachePartitions(\\s*.*)cachePartition-meta.xml");
        METADATA_PATTERNS.put("ApexClass", "forceapp(\\s*.*)classes(\\s*.*)");
        METADATA_PATTERNS.put("CleanDataService", "force-app(\\s*.*)cleanDataServices(\\s*.*)cleanDataService-meta.xml");
        METADATA_PATTERNS.put("CustomMetadata", "force-app(\\s*.*)customMetadata(\\s*.*)md-meta.xml");
        METADATA_PATTERNS.put("Dashboard", "force-app(\\s*.*)dashboards(\\s*.*)dashboard-meta.xml");
        METADATA_PATTERNS.put( "DashboardFolder", "force-app(\\s*.*)dashboards(\\s*.*)dashboardFolder-meta.xml");
        METADATA_PATTERNS.put("DuplicateRule", "force-app(\\s*.*)duplicateRules(\\s*.*)duplicateRule-meta.xml");
        METADATA_PATTERNS.put("Email", "force-app(\\s*.*)email(\\s*.*)email");
        METADATA_PATTERNS.put("EscalationRules", "force-app(\\s*.*)escalationRules(\\s*.*)escalationRules-meta.xml");
        METADATA_PATTERNS.put("FlexiPage", "force-app(\\s*.*)flexipages(\\s*.*)flexipage-meta.xml");
        METADATA_PATTERNS.put("Flow", "force-app(\\s*.*)flows(\\s*.*)flow-meta.xml");
        METADATA_PATTERNS.put("GlobalValueSet", "force-app(\\s*.*)globalValueSets(\\s*.*)globalValueSet-meta.xml");
        METADATA_PATTERNS.put("Group", "force-app(\\s*.*)groups(\\s*.*)group-meta.xml");
        METADATA_PATTERNS.put("HomePageLayout", "force-app(\\s*.*)homePageLayouts(\\s*.*)homePageLayout-meta.xml");
        METADATA_PATTERNS.put("CustomLabels", "force-app(\\s*.*)labels(\\s*.*)labels-meta.xml");
        METADATA_PATTERNS.put("Layout", "force-app(\\s*.*)layouts(\\s*.*)layout-meta.xml");
        METADATA_PATTERNS.put("LightningExperienceTheme", "force-app(\\s*.*)lightningExperienceThemes(\\s*.*)lightningExperienceTheme-meta.xml");
        METADATA_PATTERNS.put("LWC", "force-app(\\s*.*)lwc(\\s*.*)");
        METADATA_PATTERNS.put("MatchingRules", "force-app(\\s*.*)matchingRules(\\s*.*)matchingRule-meta.xml");
        METADATA_PATTERNS.put("CustomObject", "force-app(\\s*.*)objects(\\s*.*)object-meta.xml");
        METADATA_PATTERNS.put("CompactLayout", "force-app(\\s*.*)objects(\\s*.*)compactLayouts(\\s*.*)compactLayout-meta.xml");
        METADATA_PATTERNS.put("CustomField", "force-app(\\s*.*)objects(\\s*.*)fields(\\s*.*)-meta.xml");
        METADATA_PATTERNS.put("ListView", "force-app(\\s*.*)objects(\\s*.*)listViews(\\s*.*)listView-meta.xml");
        METADATA_PATTERNS.put("RecordTypes", "force-app(\\s*.*)objects(\\s*.*)recordTypes(\\s*.*)recordType-meta.xml");
        METADATA_PATTERNS.put("ValidationRule", "force-app(\\s*.*)objects(\\s*.*)validationRules(\\s*.*)validationRule-meta.xml");
        METADATA_PATTERNS.put("WebLink", "force-app(\\s*.*)objects(\\s*.*)webLinks(\\s*.*)webLink-meta.xml");
        METADATA_PATTERNS.put("FieldSet", "force-app(\\s*.*)objects(\\s*.*)fieldSets(\\s*.*)fieldSet-meta.xml");
        METADATA_PATTERNS.put("BusinessProcess", "force-app(\\s*.*)objects(\\s*.*)businessProcesses(\\s*.*)businessProcess-meta.xml");
        METADATA_PATTERNS.put("CustomObjectTranslation", "force-app(\\s*.*)objectTranslations(\\s*.*)objectTranslation-meta.xml");
        METADATA_PATTERNS.put("PathAssistant", "force-app(\\s*.*)pathAssistants(\\s*.*)pathAssistant-meta.xml");
        METADATA_PATTERNS.put("PermissionSet", "force-app(\\s*.*)permissionsets(\\s*.*)permissionset-meta.xml");
        METADATA_PATTERNS.put("ProfilePasswordPolicy", "force-app(\\s*.*)profilePasswordPolicies(\\s*.*)profilePasswordPolicy-meta.xml");
        METADATA_PATTERNS.put("Profile", "force-app(\\s*.*)profiles(\\s*.*)profile-meta.xml");
        METADATA_PATTERNS.put("ProfileSessionSetting", "force-app(\\s*.*)profileSessionSettings(\\s*.*)profileSessionSetting-meta.xml");
        METADATA_PATTERNS.put("Queue", "force-app(\\s*.*)queues(\\s*.*)queue-meta.xml");
        METADATA_PATTERNS.put("QuickAction", "force-app(\\s*.*)quickActions(\\s*.*)quickAction-meta.xml");
        METADATA_PATTERNS.put("RecordActionDeployment", "force-app(\\s*.*)recordActionDeployments(\\s*.*)deployment-meta.xml");
        METADATA_PATTERNS.put("RemoteSiteSetting", "force-app(\\s*.*)remoteSiteSettings(\\s*.*)remoteSite-meta.xml");
        METADATA_PATTERNS.put("Report", "force-app(\\s*.*)reports(\\s*.*)report-meta.xml");
        METADATA_PATTERNS.put("ReportFolder", "force-app(\\s*.*)reports(\\s*.*)reportFolder-meta.xml");
        METADATA_PATTERNS.put("ReportType", "force-app(\\s*.*)reportTypes(\\s*.*)reportType-meta.xml");
        METADATA_PATTERNS.put("SharingRules", "force-app(\\s*.*)sharingRules(\\s*.*)sharingRules-meta.xml");
        METADATA_PATTERNS.put("StandardValueSet", "force-app(\\s*.*)standardValueSets(\\s*.*)standardValueSet-meta.xml");
        METADATA_PATTERNS.put("CustomTab", "force-app(\\s*.*)tabs(\\s*.*)tab-meta.xml");
        METADATA_PATTERNS.put("ApexTestSuite", "force-app(\\s*.*)testSuites(\\s*.*)testSuite-meta.xml");
        METADATA_PATTERNS.put("TopicsForObjects", "force-app(\\s*.*)topicsForObjects(\\s*.*)topicsForObjects-meta.xml");
        METADATA_PATTERNS.put("Trigger", "force-app(\\s*.*)triggers(\\s*.*)");
        METADATA_PATTERNS.put("Workflow", "force-app(\\s*.*)workflows(\\s*.*)workflow-meta.xml");
        METADATA_PATTERNS.put("Letterhead", "force-app(\\s*.*)letterhead(\\s*.*)letter-meta.xml");
        METADATA_PATTERNS.put("ObjectTranslations", "force-app(\\s*.*)objectTranslations(\\s*.*)fieldTranslation-meta.xml");
        METADATA_PATTERNS.put("ContentAssets", "force-app(\\s*.*)contentassets(\\s*.*)");
        METADATA_PATTERNS.put("Documents", "force-app(\\s*.*)documents(\\s*.*)");
        METADATA_PATTERNS.put("StaticResources", "force-app(\\s*.*)staticresources(\\s*.*)");
        METADATA_PATTERNS.put("Settings", "force-app(\\s*.*)settings(\\s*.*)settings-meta.xml");
    }
}
