/*
 * MONOLITH 要求事項・方式設計・検証モデル (SysML v2 Textual Notation - v2)
 * 対象システム: MONOLITH (3D地球儀リアルタイム地震モニター & Lo-Fiチルミュージックプレイヤー)
 */

package MonolithSpecification {
    private import ScalarValues::*;

    package MonolithData {
        enum def DesignTheme { enum WhiteBaseMonochrome; }
        enum def PlaybackMode { enum Live; enum History30D; }
        enum def MagnitudeFilter { enum All; enum M4Plus; enum M5Plus; enum M6Plus; }
        enum def VerdictKind { enum Pass; enum Fail; enum Inconclusive; enum Error; }

        item def GeoJsonEarthquakeFeed {
            attribute eventCount : Integer;
            attribute periodDays : Integer;
        }
        item def EarthquakeEvent {
            attribute eventId : String;
            attribute magnitude : Real;
            attribute latitude : Real;
            attribute longitude : Real;
            attribute depthKm : Real;
            attribute timestampEpochMs : Integer;
            attribute placeCaption : String;
            attribute isSimulated : Boolean;
        }
        item def TopoJsonMapData {
            attribute isFallbackEmbedded : Boolean;
            attribute includesCountryBorders : Boolean;
        }
        item def UserPointerInput {
            attribute dx : Real;
            attribute dy : Real;
            attribute zoomDelta : Real;
        }
        item def AudioSignal {
            attribute sampleRateHz : Integer;
        }
        item def ModeSwitchTo30D;
        item def ModeSwitchToLive;
        item def SimTriggerSignal;
        item def UserInteractionUnlockSignal;
    }

    package MonolithInterfaces {
        private import MonolithData::*;
        port def UsgsApiPort { in item feed : GeoJsonEarthquakeFeed; }
        port def MapDataPort { in item mapData : TopoJsonMapData; }
        port def UserInputPort {
            in item pointerInput : UserPointerInput;
            in item simTrigger : SimTriggerSignal;
            in item unlockSignal : UserInteractionUnlockSignal;
        }
        port def EarthquakeEventOutPort { out item quakeEvent : EarthquakeEvent; }
        port def EarthquakeEventInPort { in item quakeEvent : EarthquakeEvent; }
        port def AudioOutputPort { out item audioOut : AudioSignal; }
    }

    package MonolithRequirements {
        private import MonolithData::*;
        private import MonolithArchitecture::*;

        package FunctionalRequirements {
            requirement <'FR-01'> globeDisplay {
                doc /* 3D空間上に磁器調マットホワイトの地球儀と大陸海岸線・国境線を描画する。初期表示時は画面サイズ・縦横比にかかわらず地球全体が余白を持って収まるスケールとする。 */
                subject cam : SceneCameraModule;
                require constraint {
                    cam.initialDistanceRadiusRatio == 3.68 and
                    cam.porcelainLightingShaderEnabled == true and
                    cam.fresnelRimHaloEnabled == true
                }
            }
            requirement <'FR-02'> interactiveControl {
                doc /* マウスドラッグおよびタッチスライドによる回転操作において、指やカーソルの移動方向と地球表面の移動方向を一致させる。ズーム、慣性移動、自動回転ON/OFFに対応する。 */
                subject cam : SceneCameraModule;
                require constraint {
                    cam.matchDragDirectionToSurface == true and
                    cam.inertiaEnabled == true
                }
            }
            requirement <'FR-03'> earthquakeParticleVisualization {
                doc /* 地震発生時、震源地を黒で表現する。周囲から極小サイズかつ半透明の黒いパーティクルが螺旋状に集束し、到達と同時に震源コア・インクハロー・3重の極細3Dリップルリングが広がる演出を行う。 */
                subject fx : ParticleEffectModule;
                require constraint {
                    fx.initialSizeMinPx >= 1.0 and
                    fx.initialSizeMaxPx <= 2.4 and
                    fx.peakAlphaMin >= 0.35 and
                    fx.peakAlphaMax <= 0.48 and
                    fx.rippleRingCount == 3
                }
            }
            requirement <'FR-04'> modeSwitching {
                doc /* LIVEモードでは最新地震を定期監視して新規発生時に演出を行い、テスト用のSIMボタンも備える。HISTORY 30Dモードでは直近1ヶ月間の地震を時系列で再生（シークバー、再生速度切替、マグニチュードフィルター対応）できる。 */
                subject dataMod : QuakeDataTimelineModule;
                require constraint {
                    dataMod.livePollingIntervalSec == 60 and
                    dataMod.historyWindowDays == 30
                }
            }
            requirement <'FR-05'> lofiChillMusicPlayback {
                doc /* 外部音声ファイルに依存せず、ブラウザ内でLo-Fiチルビート（コード進行、スウィングドラム、レコードノイズ）をリアルタイム生成・再生し、白黒の波形ビジュアライザーを表示する。 */
                subject audio : WebAudioEngineModule;
                require constraint {
                    audio.requiresExternalAudioFiles == false and
                    audio.chordPresetCount == 3 and
                    audio.analyserWaveformVisualizer == true
                }
            }
            requirement <'FR-06'> earthquakeNoiseSfx {
                doc /* 地震発生時にLo-Fiの世界観に馴染む小さく乾いた2段階ノイズ系効果音を鳴らす（設定からON/OFF切替可能）。 */
                subject audio : WebAudioEngineModule;
                require constraint {
                    audio.sfxTwoStageNoiseEnabled == true and
                    audio.unlockAudioOnFirstUserGesture == true and
                    audio.sfxToggleable == true
                }
            }
            requirement <'FR-07'> minimalUiInformationSuppression {
                doc /* 通常表示の情報量を最小限（モード切替、コンパクトなプレイヤー、発生時の1行自動フェードアウトキャプション）に抑え、詳細ログや設定はドロワー／ポップオーバー内に格納する。 */
                subject ui : MinimalHudUiModule;
                require constraint {
                    ui.singleLineAutoFadeCaption == true and
                    ui.detailsStoredInDrawer == true
                }
            }
        }

        package NonFunctionalRequirements {
            requirement <'NFR-01'> monochromeWhiteBaseDesign {
                doc /* ホワイトベースの完全モノクロームデザインとする。 */
                subject app : MonolithWebApp;
                require constraint { app.designTheme == DesignTheme::WhiteBaseMonochrome }
            }
            requirement <'NFR-02'> availabilityAndFallback {
                doc /* 外部CDNの障害やオフライン環境でも画面が真っ白にならず即座に表示されること。 */
                subject app : MonolithWebApp;
                require constraint {
                    app.mapVectorModule.embeddedFallbackMapEnabled == true and
                    app.multiCdnThreeJsFallbackEnabled == true
                }
            }
            requirement <'NFR-03'> distributionAndOperability {
                doc /* ビルド不要の単一 index.html で完結させ、GitHub Pages等の静的ホスティングで即座に公開できること。 */
                subject app : MonolithWebApp;
                require constraint {
                    app.isSingleHtmlFile == true and
                    app.requiresBuildStep == false
                }
            }
            requirement <'NFR-04'> responsiveViewportScaling {
                doc /* PC（横長）・スマートフォン（縦長）の画面比率やリサイズに応じてカメラ距離を自動補正し、地球全体が見切れないこと。 */
                subject cam : SceneCameraModule;
                require constraint { cam.dynamicAspectCorrectionEnabled == true }
            }
        }
    }

    package MonolithArchitecture {
        private import MonolithData::*;
        private import MonolithInterfaces::*;
        private import MonolithBehavior::*;

        part def UsgsEarthquakeApi { port feedOut : ~UsgsApiPort; }
        part def ExternalCdnProvider {
            attribute threeJsVersion : String = "r128 UMD";
            attribute mapDataset : String = "world-atlas@2/countries-110m.json";
            attribute fontFamilies : String = "Space Grotesk, JetBrains Mono";
            port mapOut : ~MapDataPort;
        }
        part def SceneCameraModule {
            attribute rendererBackend : String = "WebGL";
            attribute globeMaterialStyle : String = "PorcelainMatteWhiteCustomGLSL";
            attribute porcelainLightingShaderEnabled : Boolean = true;
            attribute fresnelRimHaloEnabled : Boolean = true;
            attribute dropShadowEnabled : Boolean = true;
            attribute ambientMonochromeDustEnabled : Boolean = true;
            attribute initialDistanceRadiusRatio : Real = 3.68;
            attribute matchDragDirectionToSurface : Boolean = true;
            attribute dynamicAspectCorrectionEnabled : Boolean = true;
            attribute inertiaEnabled : Boolean = true;
            attribute autoRotateToggleable : Boolean = true;
            port userInput : UserInputPort;
        }
        part def MapVectorModule {
            attribute embeddedTopoJsonDecoder : Boolean = true;
            attribute embeddedFallbackMapEnabled : Boolean = true;
            attribute worldAtlasSource : String = "world-atlas@2/countries-110m.json";
            attribute coastlineColorHex : String = "#1a1a1a";
            attribute borderLineColorHex : String = "#b5b5b0";
            attribute countryBordersEnabled : Boolean = true;
            port mapIn : MapDataPort;
        }
        part def ParticleEffectModule {
            attribute shaderType : String = "THREE.ShaderMaterial";
            attribute inkMaskFunction : String = "smoothstep(0.5, 0.05, dist)";
            attribute initialSizeMinPx : Real = 1.0;
            attribute initialSizeMaxPx : Real = 2.4;
            attribute convergingSizeMinPx : Real = 3.5;
            attribute convergingSizeMaxPx : Real = 6.5;
            attribute peakAlphaMin : Real = 0.35;
            attribute peakAlphaMax : Real = 0.48;
            attribute rippleRingCount : Integer = 3;
            attribute hasEpicenterCoreHaloAndRipple : Boolean = true;
            port quakeIn : EarthquakeEventInPort;
            perform action executeVisualEffect : RenderEarthquakeParticleEffect;
        }
        part def QuakeDataTimelineModule {
            attribute livePollingIntervalSec : Integer = 60;
            attribute liveFeedWindowHours : Integer = 24;
            attribute historyWindowDays : Integer = 30;
            attribute minPlaybackSpeed : String = "1D/10s";
            attribute maxPlaybackSpeed : String = "3D/1s";
            attribute currentMode : PlaybackMode = PlaybackMode::Live;
            attribute activeFilter : MagnitudeFilter = MagnitudeFilter::All;
            port usgsIn : UsgsApiPort;
            port quakeOut : EarthquakeEventOutPort;
            exhibit state operationMode : OperationModeStateMachine;
        }
        part def WebAudioEngineModule {
            attribute requiresExternalAudioFiles : Boolean = false;
            attribute chordPresetCount : Integer = 3;
            attribute vinylNoiseAdjustable : Boolean = true;
            attribute analyserWaveformVisualizer : Boolean = true;
            attribute sfxTwoStageNoiseEnabled : Boolean = true;
            attribute sfxMagnitudeModulation : Boolean = true;
            attribute unlockAudioOnFirstUserGesture : Boolean = true;
            attribute sfxToggleable : Boolean = true;
            port quakeIn : EarthquakeEventInPort;
            port audioOut : AudioOutputPort;
            perform action playSfx : PlayTwoStageNoiseSfx;
        }
        part def MinimalHudUiModule {
            attribute typographyFonts : String = "Space Grotesk, JetBrains Mono";
            attribute singleLineAutoFadeCaption : Boolean = true;
            attribute detailsStoredInDrawer : Boolean = true;
            attribute hasSimButton : Boolean = true;
            attribute hasCompactLofiPlayer : Boolean = true;
            port quakeIn : EarthquakeEventInPort;
            port userInput : UserInputPort;
        }

        part def MonolithWebApp {
            attribute appName : String = "MONOLITH";
            attribute designTheme : DesignTheme = DesignTheme::WhiteBaseMonochrome;
            attribute isSingleHtmlFile : Boolean = true;
            attribute requiresBuildStep : Boolean = false;
            attribute multiCdnThreeJsFallbackEnabled : Boolean = true;

            part sceneCameraModule : SceneCameraModule;
            part mapVectorModule : MapVectorModule;
            part particleEffectModule : ParticleEffectModule;
            part quakeDataModule : QuakeDataTimelineModule;
            part audioModule : WebAudioEngineModule;
            part hudUiModule : MinimalHudUiModule;

            flow of EarthquakeEvent from quakeDataModule.quakeOut.quakeEvent to particleEffectModule.quakeIn.quakeEvent;
            flow of EarthquakeEvent from quakeDataModule.quakeOut.quakeEvent to audioModule.quakeIn.quakeEvent;
            flow of EarthquakeEvent from quakeDataModule.quakeOut.quakeEvent to hudUiModule.quakeIn.quakeEvent;
        }

        part monolithContext {
            part app : MonolithWebApp;
            part usgsApi : UsgsEarthquakeApi;
            part cdn : ExternalCdnProvider;

            flow of GeoJsonEarthquakeFeed from usgsApi.feedOut.feed to app.quakeDataModule.usgsIn.feed;
            flow of TopoJsonMapData from cdn.mapOut.mapData to app.mapVectorModule.mapIn.mapData;
        }
    }

    package MonolithBehavior {
        private import MonolithData::*;

        state def OperationModeStateMachine {
            entry; then liveMode;
            state liveMode;
            state history30DMode;
            transition liveToHistory first liveMode accept ModeSwitchTo30D then history30DMode;
            transition historyToLive first history30DMode accept ModeSwitchToLive then liveMode;
        }

        action def RenderEarthquakeParticleEffect {
            in event : EarthquakeEvent;
            first start;
            then action spawnAndSpiralGather;
            then action triggerEpicenterRupture;
            then done;
        }

        action def PlayTwoStageNoiseSfx {
            in event : EarthquakeEvent;
            first start;
            then action playGatherNoiseSwell;
            then action playRuptureNoiseBurst;
            then done;
        }

        action def HandleEarthquakeNotification {
            in event : EarthquakeEvent;
            action visual : RenderEarthquakeParticleEffect { in event = HandleEarthquakeNotification::event; }
            action audio : PlayTwoStageNoiseSfx { in event = HandleEarthquakeNotification::event; }
            action showSingleLineCaption;

            first start;
            then fork effectFork;
                then visual;
                then audio;
                then showSingleLineCaption;
            first visual then effectJoin;
            first audio then effectJoin;
            first showSingleLineCaption then effectJoin;
            join effectJoin;
            then done;
        }
    }

    package MonolithDeployment {
        part def GitRepository {
            attribute branchName : String = "main";
            attribute rootDirectory : String = "/";
            part indexHtml { attribute fileName : String = "index.html"; }
            part readmeMd { attribute fileName : String = "README.md"; }
        }
        part def GitHubPagesHosting {
            part repo : GitRepository;
            attribute requiresBuildPipeline : Boolean = false;
        }
    }

    package MonolithTraceability {
        private import MonolithRequirements::FunctionalRequirements::*;
        private import MonolithRequirements::NonFunctionalRequirements::*;
        private import MonolithArchitecture::*;

        part systemUnderDesign : MonolithWebApp;

        satisfy globeDisplay by systemUnderDesign.sceneCameraModule;
        satisfy interactiveControl by systemUnderDesign.sceneCameraModule;
        satisfy earthquakeParticleVisualization by systemUnderDesign.particleEffectModule;
        satisfy modeSwitching by systemUnderDesign.quakeDataModule;
        satisfy lofiChillMusicPlayback by systemUnderDesign.audioModule;
        satisfy earthquakeNoiseSfx by systemUnderDesign.audioModule;
        satisfy minimalUiInformationSuppression by systemUnderDesign.hudUiModule;

        satisfy monochromeWhiteBaseDesign by systemUnderDesign;
        satisfy availabilityAndFallback by systemUnderDesign;
        satisfy distributionAndOperability by systemUnderDesign;
        satisfy responsiveViewportScaling by systemUnderDesign.sceneCameraModule;
    }

    package MonolithVerification {
        private import MonolithData::*;
        private import MonolithRequirements::FunctionalRequirements::*;
        private import MonolithRequirements::NonFunctionalRequirements::*;
        private import MonolithArchitecture::*;

        verification def <'VC-01'> VerifyGlobeInitialScale {
            subject cam : SceneCameraModule;
            objective { verify globeDisplay; }
            action checkWebGlContextAndInitialScale;
            return verdict : VerdictKind;
        }
        verification def <'VC-02'> VerifyInteractiveDragDirection {
            subject cam : SceneCameraModule;
            objective { verify interactiveControl; }
            action simulatePointerDragAndInspect;
            return verdict : VerdictKind;
        }
        verification def <'VC-03'> VerifyParticleAndRippleShader {
            subject fx : ParticleEffectModule;
            objective { verify earthquakeParticleVisualization; }
            action triggerSimAndInspectShaderParams;
            return verdict : VerdictKind;
        }
        verification def <'VC-04'> VerifyModeSwitchingAndTimeline {
            subject dataMod : QuakeDataTimelineModule;
            objective { verify modeSwitching; }
            action toggleLiveAnd30DModes;
            return verdict : VerdictKind;
        }
        verification def <'VC-05'> VerifyLofiAudioSynthesis {
            subject audio : WebAudioEngineModule;
            objective { verify lofiChillMusicPlayback; }
            action startLofiPlaybackAndCheckAnalyser;
            return verdict : VerdictKind;
        }
        verification def <'VC-06'> VerifyTwoStageNoiseSfx {
            subject audio : WebAudioEngineModule;
            objective { verify earthquakeNoiseSfx; }
            action toggleSfxAndTriggerSim;
            return verdict : VerdictKind;
        }
        verification def <'VC-07'> VerifyMinimalHudAndDrawer {
            subject ui : MinimalHudUiModule;
            objective { verify minimalUiInformationSuppression; }
            action inspectInitialHudAndDrawerToggle;
            return verdict : VerdictKind;
        }
        verification def <'VC-08'> VerifyWhiteBaseMonochromeDesign {
            subject app : MonolithWebApp;
            objective { verify monochromeWhiteBaseDesign; }
            action measureComputedBackgroundColor;
            return verdict : VerdictKind;
        }
        verification def <'VC-09'> VerifyFallbackAvailability {
            subject app : MonolithWebApp;
            objective { verify availabilityAndFallback; }
            action blockExternalNetworkAndLoad;
            return verdict : VerdictKind;
        }
        verification def <'VC-10'> VerifySingleFileDistribution {
            subject app : MonolithWebApp;
            objective { verify distributionAndOperability; }
            action inspectRepositoryDeliverable;
            return verdict : VerdictKind;
        }
        verification def <'VC-11'> VerifyResponsiveScaling {
            subject cam : SceneCameraModule;
            objective { verify responsiveViewportScaling; }
            action testDesktopAndMobileViewports;
            return verdict : VerdictKind;
        }

        verification monolithVerificationSuite {
            subject app : MonolithWebApp;
            verification vc01 : VerifyGlobeInitialScale { subject = app.sceneCameraModule; }
            verification vc02 : VerifyInteractiveDragDirection { subject = app.sceneCameraModule; }
            verification vc03 : VerifyParticleAndRippleShader { subject = app.particleEffectModule; }
            verification vc04 : VerifyModeSwitchingAndTimeline { subject = app.quakeDataModule; }
            verification vc05 : VerifyLofiAudioSynthesis { subject = app.audioModule; }
            verification vc06 : VerifyTwoStageNoiseSfx { subject = app.audioModule; }
            verification vc07 : VerifyMinimalHudAndDrawer { subject = app.hudUiModule; }
            verification vc08 : VerifyWhiteBaseMonochromeDesign { subject = app; }
            verification vc09 : VerifyFallbackAvailability { subject = app; }
            verification vc10 : VerifySingleFileDistribution { subject = app; }
            verification vc11 : VerifyResponsiveScaling { subject = app.sceneCameraModule; }
        }
    }
}
