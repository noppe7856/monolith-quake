package MonolithEngineeringSystem {
    private import ScalarValues::*;
    private import MonolithSpecification::MonolithData::VerdictKind;

    package MonolithDevelopmentEnvironment {
        item def SysmlModelArtifact {
            attribute fileName : String = "monolith_specification-v2.sysml";
            attribute notation : String = "SysML v2 Textual Notation";
        }
        item def WebAppSourceArtifact {
            attribute fileName : String = "index.html";
            attribute isSingleFile : Boolean = true;
        }
        item def TestSuiteArtifact {
            attribute fileName : String = "monolith.spec.mjs";
            attribute framework : String = "Playwright";
        }
        item def VerificationReport {
            attribute overallVerdict : VerdictKind;
            attribute passedCaseCount : Integer;
            attribute totalCaseCount : Integer = 11;
        }
        item def GitCommitPayload {
            attribute branchName : String = "main";
            attribute commitMessage : String;
        }

        port def ModelOutPort { out item model : SysmlModelArtifact; }
        port def ModelInPort  { in item model : SysmlModelArtifact; }
        port def SourceOutPort { out item source : WebAppSourceArtifact; }
        port def SourceInPort  { in item source : WebAppSourceArtifact; }
        port def TestSuiteOutPort { out item testSuite : TestSuiteArtifact; }
        port def TestSuiteInPort  { in item testSuite : TestSuiteArtifact; }
        port def ReportOutPort { out item report : VerificationReport; }
        port def ReportInPort  { in item report : VerificationReport; }
        port def GitPushOutPort { out item payload : GitCommitPayload; }
        port def GitPushInPort  { in item payload : GitCommitPayload; }

        part def ModelingToolchain {
            doc /* SysML v2 モデリング・構文検証・可視化環境（Antigravity構成） */
            attribute editor : String = "Antigravity";
            attribute sysmlExtension : String = "SysML v2 Language Support / AI-Assisted MBSE";
            port modelOut : ModelOutPort;
            port reportIn : ReportInPort;
        }
        part def ImplementationEditor {
            doc /* HTML5/CSS3/JS/GLSL 実装・テストコード編集環境（Antigravity構成） */
            attribute editor : String = "Antigravity";
            attribute requiresBundler : Boolean = false;
            port modelIn : ModelInPort;
            port sourceOut : SourceOutPort;
            port testSuiteOut : TestSuiteOutPort;
        }
        part def VerificationRuntime {
            attribute runtime : String = "Node.js (LTS)";
            attribute testRunner : String = "@playwright/test";
            attribute browserEngine : String = "Chromium";
            port sourceIn : SourceInPort;
            port testSuiteIn : TestSuiteInPort;
            port reportOut : ReportOutPort;
        }
        part def LocalVersionControl {
            attribute gitClient : String = "Git";
            attribute cliTool : String = "GitHub CLI (gh)";
            port modelIn : ModelInPort;
            port sourceIn : SourceInPort;
            port testSuiteIn : TestSuiteInPort;
            port pushOut : GitPushOutPort;
        }

        part def LocalWorkstation {
            attribute osEnvironment : String = "Windows + WSL2 / Desktop OS";
            attribute localBrowserForManualCheck : String = "Chrome / Edge (WebGL & Web Audio enabled)";

            part modelingTool : ModelingToolchain;
            part codeEditor : ImplementationEditor;
            part testRuntime : VerificationRuntime;
            part vcsClient : LocalVersionControl;

            flow of SysmlModelArtifact from modelingTool.modelOut.model to codeEditor.modelIn.model;
            flow of SysmlModelArtifact from modelingTool.modelOut.model to vcsClient.modelIn.model;
            flow of WebAppSourceArtifact from codeEditor.sourceOut.source to testRuntime.sourceIn.source;
            flow of WebAppSourceArtifact from codeEditor.sourceOut.source to vcsClient.sourceIn.source;
            flow of TestSuiteArtifact from codeEditor.testSuiteOut.testSuite to testRuntime.testSuiteIn.testSuite;
            flow of TestSuiteArtifact from codeEditor.testSuiteOut.testSuite to vcsClient.testSuiteIn.testSuite;
            flow of VerificationReport from testRuntime.reportOut.report to modelingTool.reportIn.report;
        }

        part def GitHubPlatform {
            attribute repositoryHosting : String = "GitHub";
            attribute pagesEnabled : Boolean = true;
            attribute deployBranch : String = "main";
            attribute deployRoot : String = "/";
            attribute ciRunnerOptional : String = "GitHub Actions (Playwright E2E)";
            port pushIn : GitPushInPort;
        }

        part monolithDevEnvironmentContext {
            part workstation : LocalWorkstation;
            part github : GitHubPlatform;
            flow of GitCommitPayload from workstation.vcsClient.pushOut.payload to github.pushIn.payload;
        }
    }

    package MonolithDevelopmentModel {
        private import MonolithDevelopmentEnvironment::*;

        part def SystemEngineer;
        part def AutomatedVerifier;

        item def ChangeRequest;
        item def ModelBaselineFrozen;
        item def ImplementationSynced;
        item def VerificationPassed;
        item def VerificationFailed;
        item def ReleaseCompleted;

        state def DevelopmentLifecycleStateMachine {
            entry; then modelingPhase;
            state modelingPhase;
            state implementationPhase;
            state verificationPhase;
            state releasePhase;

            transition freezeModel first modelingPhase accept ModelBaselineFrozen then implementationPhase;
            transition startVerification first implementationPhase accept ImplementationSynced then verificationPhase;
            transition approveRelease first verificationPhase accept VerificationPassed then releasePhase;
            transition reworkOnFailure first verificationPhase accept VerificationFailed then modelingPhase;
            transition nextIteration first releasePhase accept ChangeRequest then modelingPhase;
        }

        action def MbseIterativeVModelWorkflow {
            in changeReq : ChangeRequest;
            out finalReport : VerificationReport;

            action updateRequirementsAndArchitecture { out model : SysmlModelArtifact; }
            action updateTraceabilityAndVerificationCases { in model : SysmlModelArtifact; out frozenModel : SysmlModelArtifact; }
            action syncWebAppImplementation { in model : SysmlModelArtifact; out source : WebAppSourceArtifact; }
            action syncPlaywrightTestCode { in model : SysmlModelArtifact; out testSuite : TestSuiteArtifact; }
            action executeAutomatedVerification { in source : WebAppSourceArtifact; in testSuite : TestSuiteArtifact; out report : VerificationReport; }
            action commitAndDeployToGitHubPages { in model : SysmlModelArtifact; in source : WebAppSourceArtifact; in testSuite : TestSuiteArtifact; }

            first start;
            then merge iterationStart;
            then updateRequirementsAndArchitecture;
            then updateTraceabilityAndVerificationCases;
            then fork syncFork;
                then syncWebAppImplementation;
                then syncPlaywrightTestCode;
            first syncWebAppImplementation then syncJoin;
            first syncPlaywrightTestCode then syncJoin;
            join syncJoin;
            then executeAutomatedVerification;
            then decide verificationGate;
                if executeAutomatedVerification.report.overallVerdict == VerdictKind::Pass
                    then commitAndDeployToGitHubPages;
                else
                    then iterationStart;
            first commitAndDeployToGitHubPages then done;

            flow from updateRequirementsAndArchitecture.model to updateTraceabilityAndVerificationCases.model;
            flow from updateTraceabilityAndVerificationCases.frozenModel to syncWebAppImplementation.model;
            flow from updateTraceabilityAndVerificationCases.frozenModel to syncPlaywrightTestCode.model;
            flow from syncWebAppImplementation.source to executeAutomatedVerification.source;
            flow from syncPlaywrightTestCode.testSuite to executeAutomatedVerification.testSuite;
            flow from updateTraceabilityAndVerificationCases.frozenModel to commitAndDeployToGitHubPages.model;
            flow from syncWebAppImplementation.source to commitAndDeployToGitHubPages.source;
            flow from syncPlaywrightTestCode.testSuite to commitAndDeployToGitHubPages.testSuite;
        }
    }
}
