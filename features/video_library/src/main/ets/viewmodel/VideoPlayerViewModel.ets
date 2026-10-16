import { AVPlayerManager, MediaSessionManager } from 'player';
import { common, Context } from '@kit.AbilityKit';
import { media } from '@kit.MediaKit';
import { display, PiPWindow, window } from '@kit.ArkUI';
import { settings } from '@kit.BasicServicesKit';
import { audio } from '@kit.AudioKit';
import { SettingKey, Settings, VideoRepeatMode } from 'data_storage';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';
import { VideoItemViewModelList } from './VideoListViewModel';
import { VideoItemViewModel } from './VideoItemViewModel';
import { ContinuousTaskManager } from 'util';
import { ShutdownOption } from '../view/ShutdownDialog';
import { avSession } from '@kit.AVSessionKit';
import { VideoCastViewModel } from './VideoCastViewModel';

const SEEK_TIME = 10000;
const VOLUME_VALUE = 1.0;
const BRIGHT_VALUE = 0.067;
const ONE_HUNDRED_VP = 100;
const MAX_VOLUME_LEVEL = 15;
const MAIN_NAV_ID = 'MainNav';
const MAX_WINDOW_BRIGHTNESS = 1.0;
const MAX_SCREEN_BRIGHTNESS = 255;


@Observed
export class VideoPlayerViewModel {
  @Track duration: number = 0;
  @Track currTime: number = 0;
  @Track brightness: number = 0;
  @Track volumeLevel: number = 0;
  @Track isCasting: boolean = false;
  @Track isPlaying: boolean = false;
  @Track isLocking: boolean = false;
  @Track isLandscape: boolean = false;
  @Track isCtrlPanelShow: boolean = false;
  @Track isSeeking: boolean = false;
  @Track isSpeeding: boolean = false;
  @Track isControlVolume: boolean = false;
  @Track isControlBrightness: boolean = false;
  @Track currVideoItem?: VideoItemViewModel;
  @Track videoList?: VideoItemViewModelList;
  @Track shutdownAfterComplete: boolean = false;
  @Track isListenVideoBackground: boolean = true;
  @Track shutdownOption: ShutdownOption = ShutdownOption.None;
  @Track xComponentCtrl: XComponentController = new XComponentController();
  @Track videoRepeatMode: VideoRepeatMode = VideoRepeatMode.SINGLE_NON_REPEAT;
  @Track playbackSpeed: media.PlaybackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
  private videoPlayer: AVPlayerManager = new AVPlayerManager();
  private videoCastViewModel?: VideoCastViewModel;
  private settings: Settings = new Settings();
  private shutdownDate?: Date;
  private startSeekTime: number = 0;
  private startBrightness: number = 0;
  private startVolumeLevel: number = 0;
  private isBackground: boolean = false;
  private slideLeftSide: boolean = false;
  private pipController?: PiPWindow.PiPController;
  private pipState: PiPWindow.PiPState = PiPWindow.PiPState.ERROR;

  constructor() {
    let audioMgr = audio.getAudioManager();
    let audioVolumeMgr = audioMgr.getVolumeManager();
    try {
      this.volumeLevel = audioVolumeMgr.getVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC);
    } catch (error) {
      console.error(`Failed to getVolumeByStream. Cause: ${JSON.stringify(error)}`);
    }
  }

  async initPlayer(surfaceId: string, context: Context): Promise<void> {
    this.videoPlayer.registerCallback('durationUpdate', (duration: number) => {
      this.duration = duration;
    });
    this.videoPlayer.registerCallback('timeUpdate', (timeMs: number) => {
      if (!this.isSeeking) {
        this.currTime = timeMs;
        MediaSessionManager.getInstance().updateElapsedTime(timeMs);
      }
      if (!this.shutdownAfterComplete && this.shutdownDate) {
        if (Date.now() >= this.shutdownDate.getTime()) {
          this.shutdownOption = ShutdownOption.None;
          this.clearShutdownDate();
          this.pause();
        }
      }
    });
    this.videoPlayer.registerCallback('seekDone', (timeMs: number) => {
      this.currTime = timeMs;
      this.isSeeking = false;
      MediaSessionManager.getInstance().updatePlayPosition(timeMs);
    });
    this.videoPlayer.registerCallback('stateChange', (state: media.AVPlayerState) => {
      this.isPlaying = (state === 'playing');
      MediaSessionManager.getInstance().updatePlayState(this.currTime, state);

      if (state === 'completed') {
        if (this.shutdownAfterComplete) {
          this.clearShutdownDate();
          this.shutdownAfterComplete = false;
          this.shutdownOption = ShutdownOption.None;
          return;
        }
        switch (this.videoRepeatMode) {
          case VideoRepeatMode.LIST_REPEAT:
            if (this.videoList) {
              if (this.videoList.length > 1) {
                this.switchNext(context);
              } else {
                this.setVideoAsset(context);
              }
            }
            break;
          case VideoRepeatMode.SINGLE_REPEAT:
            this.setVideoAsset(context);
            break;
          case VideoRepeatMode.LIST_NON_REPEAT:
            if (this.currVideoItem && this.videoList && this.videoList.length > 0) {
              const lastVideoItem = this.videoList[this.videoList.length - 1];
              if (this.currVideoItem !== lastVideoItem) {
                this.switchNext(context);
              }
            }
            break;
          default:
            break;
        }
      }
    });
    await this.videoPlayer.initPlayer(surfaceId);

    await this.settings.initPreference(context);
    this.videoRepeatMode = (await this.settings.getSetting(SettingKey.VIDEO_REPEAT_MODE)) as VideoRepeatMode;
    this.isListenVideoBackground = (await this.settings.getSetting(SettingKey.LISTEN_VIDEO_BACKGROUND)) as boolean;
  }

  async initSession(context: Context) {
    MediaSessionManager.getInstance().registerCallback('play', () => {
      this.play(context);
    });
    MediaSessionManager.getInstance().registerCallback('pause', () => {
      this.pause();
    });
    MediaSessionManager.getInstance().registerCallback('seek', (timeMs: number) => {
      this.seek(timeMs);
    });
    MediaSessionManager.getInstance().registerCallback('rewind', (timeS?: number) => {
      if (timeS) {
        let timeMs = this.currTime - timeS * 1000;
        this.seek(timeMs);
      }
    });
    MediaSessionManager.getInstance().registerCallback('fastForward', (timeS?: number) => {
      if (timeS) {
        let timeMs = this.currTime + timeS * 1000;
        this.seek(timeMs);
      }
    });
    MediaSessionManager.getInstance()
      .registerCallback('outputDeviceChange',
        async (state: avSession.ConnectionState, device: avSession.OutputDeviceInfo) => {
          const currDevice = device.devices[0];
          if (currDevice.castCategory === avSession.AVCastCategory.CATEGORY_REMOTE &&
            state === avSession.ConnectionState.STATE_CONNECTED) {
            const castController = await MediaSessionManager.getInstance().getAVCastController();
            this.videoCastViewModel = new VideoCastViewModel(castController!);

            this.videoPlayer.setAVMuted(true);
            const videoInfo = this.currVideoItem!.videoInfo;
            await this.videoCastViewModel.setCastVideo(videoInfo, this.duration, this.currTime);
            this.isCasting = true;
          } else {
            this.isCasting = false;
            this.videoPlayer.setAVMuted(false);
            this.videoCastViewModel?.releaseAVCast();
            MediaSessionManager.getInstance().stopCasting();
          }
        });
    if (this.videoList && this.videoList.length > 1) {
      MediaSessionManager.getInstance().registerCallback('playPrevious', () => {
        if (this.isBackground && !this.isListenVideoBackground) {
          return;
        }
        this.switchPrev(context);
      });
      MediaSessionManager.getInstance().registerCallback('playNext', () => {
        if (this.isBackground && !this.isListenVideoBackground) {
          return;
        }
        this.switchNext(context);
      });
    }
    await MediaSessionManager.getInstance().initVideoSession(context);
  }

  async setVideoAsset(context: Context): Promise<void> {
    if (!this.currVideoItem) {
      return;
    }

    await this.videoPlayer.setMediaAsset(this.currVideoItem.videoInfo.videoPath);

    await this.initSession(context);
    const currState: media.AVPlayerState = this.videoPlayer.getState() ?? 'released';
    await MediaSessionManager.getInstance().setVideoAsset(this.currVideoItem.videoInfo, this.currTime, currState);
  }

  async switchNext(context: Context): Promise<void> {
    if (!this.currVideoItem) {
      return;
    }
    if (!this.videoList || this.videoList.length <= 1) {
      return;
    }
    if (this.isCasting) {
      this.isCasting = false;
      this.videoCastViewModel?.releaseAVCast();
      MediaSessionManager.getInstance().stopCasting();
    }

    const currVideoId = this.currVideoItem.videoInfo.id;
    const currIdx = this.videoList.findIndex((item: VideoItemViewModel) => {
      return currVideoId === item.videoInfo.id;
    });
    if (currIdx === -1) {
      return;
    }
    const nextIdx = (currIdx + 1) % this.videoList.length;
    this.currVideoItem = this.videoList[nextIdx];
    await this.setVideoAsset(context);
  }

  async switchPrev(context: Context): Promise<void> {
    if (!this.currVideoItem) {
      return;
    }
    if (!this.videoList || this.videoList.length <= 1) {
      return;
    }

    const currVideoId = this.currVideoItem.videoInfo.id;
    const currIdx = this.videoList.findIndex((item: VideoItemViewModel) => {
      return currVideoId === item.videoInfo.id;
    });
    if (currIdx === -1) {
      return;
    }
    const prevIdx = currIdx === 0 ? this.videoList.length - 1 : (currIdx - 1) % this.videoList.length;
    this.currVideoItem = this.videoList[prevIdx];
    this.setVideoAsset(context);
  }

  async play(context: Context): Promise<void> {
    if (this.isBackground) {
      if (this.isListenVideoBackground) {
        if (!(await ContinuousTaskManager.hasContinuousTasks(context))) {
          await ContinuousTaskManager.startContinuousTask(context);
        }
        if (this.isCasting) {
          this.videoCastViewModel?.play();
        }
        await this.videoPlayer.play();
      }
    } else {
      if (this.isCasting) {
        this.videoCastViewModel?.play();
      }
      await this.videoPlayer.play();
    }
  }

  async pause(): Promise<void> {
    if (this.isCasting) {
      this.videoCastViewModel?.pause();
    }
    await this.videoPlayer.pause();
  }

  seek(timeMs: number): void {
    timeMs = Math.min(this.duration, Math.max(0, timeMs));
    if (this.isCasting) {
      this.videoCastViewModel?.seek(timeMs);
    }
    this.videoPlayer.seek(timeMs);
  }

  setSpeed(speed: media.PlaybackSpeed): void {
    this.videoPlayer.setSpeed(speed);
    switch (speed) {
      case media.PlaybackSpeed.SPEED_FORWARD_0_75_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 0.75);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_00_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 1.00);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_25_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 1.25);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_75_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 1.75);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_2_00_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 2.00);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_0_50_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 0.50);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_50_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 1.50);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_3_00_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 3.00);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_0_25_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 0.25);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_0_125_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 0.125);
        break;
    }
  }

  async setRepeatMode(repeatMode: VideoRepeatMode): Promise<void> {
    this.videoRepeatMode = repeatMode;
    this.settings.putSetting(SettingKey.VIDEO_REPEAT_MODE, repeatMode);
  }

  async setListenVideoBG(isOn: boolean): Promise<void> {
    this.isListenVideoBackground = isOn;
    this.settings.putSetting(SettingKey.LISTEN_VIDEO_BACKGROUND, isOn);
  }

  async startPip(context: Context): Promise<void> {
    if (!PiPWindow.isPiPEnabled()) {
      console.error(`picture in picture disabled for current OS`);
      return;
    }
    if (!this.currVideoItem) {
      console.error(`Current video item is undefined when start pip`);
      return;
    }

    const metadata = JSON.parse(this.currVideoItem.videoInfo.metadata) as media.AVMetadata;

    const config: PiPWindow.PiPConfiguration = {
      context: context,
      navigationId: MAIN_NAV_ID,
      componentController: this.xComponentCtrl,
      templateType: PiPWindow.PiPTemplateType.VIDEO_PLAY,
      contentWidth: metadata.videoWidth ? parseInt(metadata.videoWidth) : undefined,
      contentHeight: metadata.videoHeight ? parseInt(metadata.videoHeight) : undefined,
    };
    try {
      this.pipController = await PiPWindow.create(config);
      this.initPipController(this.pipController);
      await this.pipController.startPiP();
    } catch (error) {
      console.error(`Failed to start picture in picture`);
    }
  }

  async stopPip(): Promise<void> {
    if (this.pipController) {
      try {
        await this.pipController.stopPiP();
      } catch (error) {
        console.error(`Failed to invoke stopPiP. Cause: ${JSON.stringify(error)}`);
      }
    }
  }

  async release(): Promise<void> {
    if (this.isCasting) {
      await MediaSessionManager.getInstance().stopCasting();
    }
    await MediaSessionManager.getInstance().release();
    await this.videoCastViewModel?.releaseAVCast();
    await this.videoPlayer.release();
    this.reset();
  }

  onForeground() {
    this.isBackground = false;
  }

  onBackground(context: Context) {
    this.isBackground = true;
    if (this.isPlaying) {
      if (this.isListenVideoBackground) {
        ContinuousTaskManager.startContinuousTask(context);
      } else {
        this.pause();
      }
    }
  }

  async shareVideo(context: common.UIAbilityContext) {
    if (!this.currVideoItem) {
      return;
    }

    let utdTypeId = utd.getUniformDataTypeByFilenameExtension('.mp4', utd.UniformDataType.VIDEO);
    let shareData: systemShare.SharedData | undefined = undefined;
    shareData = new systemShare.SharedData({
      utd: utdTypeId,
      title: this.currVideoItem.videoName,
      uri: fileUri.getUriFromPath(this.currVideoItem.videoInfo.videoPath),
      thumbnailUri: fileUri.getUriFromPath(this.currVideoItem.videoInfo.thumbnailPath),
    });
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    await controller.show(context, ({
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DETAIL,
    }))
      .then(() => {
        console.info(`ShareController show success.`);
      })
      .catch((err: BusinessError<void>) => {
        console.error(`ShareController show error. Cause: ${JSON.stringify(err)}`);
      });
  }

  async startHorizontalSlide(): Promise<void> {
    this.startSeekTime = this.currTime;
  }

  async updateHorizontalSlide(offsetX: number): Promise<void> {
    let seekTime = this.startSeekTime + (offsetX / ONE_HUNDRED_VP) * SEEK_TIME;
    this.currTime = Math.max(0, Math.min(seekTime, this.duration));
  }

  async endHorizontalSlide(): Promise<void> {
    this.seek(this.currTime);
  }

  async startVerticalSlide(context: common.UIAbilityContext, uiContext: UIContext, globalX: number): Promise<void> {
    let screenWidthVp: number = 0;
    try {
      screenWidthVp = uiContext.px2vp(display.getDefaultDisplaySync().width);
    } catch (error) {
      console.error(`Failed to invoke getDefaultDisplaySync. Cause: ${JSON.stringify(error)}`);
      return;
    }
    if (globalX <= screenWidthVp / 2) {
      this.slideLeftSide = true;
    } else {
      this.slideLeftSide = false;
    }
    if (this.slideLeftSide) {
      this.isControlBrightness = true;
      let windowClass: window.Window | undefined;
      try {
        windowClass = await context.windowStage.getMainWindow();
      } catch (error) {
        console.error(`Failed to getMainWindow. Cause: ${JSON.stringify(error)}`);
        return;
      }
      try {
        this.startBrightness = windowClass.getWindowProperties().brightness;
        if (this.startBrightness === -1) {
          let brightStr = settings.getValueSync(context, settings.display.SCREEN_BRIGHTNESS_STATUS, '100');
          this.startBrightness = parseInt(brightStr) / MAX_SCREEN_BRIGHTNESS;
        }
      } catch (error) {
        console.error(`Failed to getWindowProperties. Cause: ${JSON.stringify(error)}`);
        return;
      }
    } else {
      this.isControlVolume = true;
      let audioMgr = audio.getAudioManager();
      let audioVolumeMgr = audioMgr.getVolumeManager();
      try {
        this.startVolumeLevel = audioVolumeMgr.getVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC);
      } catch (error) {
        console.error(`Failed to getVolumeByStream. Cause: ${JSON.stringify(error)}`);
      }
    }
  }

  async updateVerticalSlide(context: common.UIAbilityContext, offsetY: number): Promise<void> {
    if (this.slideLeftSide) {
      let windowClass: window.Window | undefined;
      try {
        windowClass = await context.windowStage.getMainWindow();
      } catch (error) {
        console.error(`Failed to getMainWindow. Cause: ${JSON.stringify(error)}`);
        return;
      }
      let brightnessVal = this.startBrightness - (offsetY / ONE_HUNDRED_VP) * BRIGHT_VALUE;
      this.brightness = Math.min(MAX_WINDOW_BRIGHTNESS, Math.max(0, brightnessVal));
      try {
        await windowClass.setWindowBrightness(this.brightness);
      } catch (error) {
        console.error(`Failed to setWindowBrightness. Cause: ${JSON.stringify(error)}`);
        return;
      }
    } else {
      let volumeLevel = this.startVolumeLevel - (offsetY / ONE_HUNDRED_VP) * VOLUME_VALUE;
      this.volumeLevel = Math.min(MAX_VOLUME_LEVEL, Math.max(0, volumeLevel));
    }
  }

  async setWindowOrientation(context: common.UIAbilityContext, orientation: window.Orientation): Promise<void> {
    await context.windowStage.getMainWindow()
      .then((windowClass: window.Window) => {
        windowClass.setPreferredOrientation(orientation)
          .then(() => {
            this.isLandscape = orientation === window.Orientation.LANDSCAPE;
          })
          .catch((error: BusinessError) => {
            console.error(`Failed to set window orientation to ${orientation}, Cause: ${JSON.stringify(error)}`);
          });
      })
      .catch((error: BusinessError) => {
        console.error(`Failed to getMainWindow, Cause: ${JSON.stringify(error)}`);
      });
  }

  async setSystemBarEnable(context: common.UIAbilityContext, enable: boolean) {
    context.windowStage.getMainWindow()
      .then(async (windowClass: window.Window) => {
        await windowClass.setSpecificSystemBarEnabled('navigationIndicator', enable)
          .catch((err: BusinessError) => {
            console.error(`Failed to set system status bar enable to ${enable}. Cause: ${JSON.stringify(err)}`);
          });
        await windowClass.setSpecificSystemBarEnabled('status', enable)
          .catch((err: BusinessError) => {
            console.error(`Failed to set system status bar enable to ${enable}. Cause: ${JSON.stringify(err)}`);
          });
      })
      .catch((error: BusinessError) => {
        console.error(`Failed to getMainWindow, Cause: ${JSON.stringify(error)}`);
      });
  }

  async setDefaultBrightness(context: common.UIAbilityContext): Promise<void> {
    let windowClass: window.Window | undefined;
    try {
      windowClass = await context.windowStage.getMainWindow();
    } catch (error) {
      console.error(`Failed to getMainWindow. Cause: ${JSON.stringify(error)}`);
      return;
    }
    try {
      await windowClass.setWindowBrightness(-1.0);
    } catch (error) {
      console.error(`Failed to setWindowBrightness. Cause: ${JSON.stringify(error)}`);
      return;
    }
  }

  async setControlPanelShow() {
    this.isCtrlPanelShow = !this.isCtrlPanelShow;
  }

  getShutdownTimeMs(): number {
    if (this.shutdownAfterComplete) {
      return this.duration - this.currTime;
    }
    if (this.shutdownDate) {
      return this.shutdownDate.getTime() - Date.now();
    }
    return -1;
  }

  setShutdownDate(hour: number, minutes: number) {
    const shutdownMs = Date.now() + hour * 60 * 60 * 1000 + minutes * 60 * 1000;
    this.shutdownDate = new Date(shutdownMs);
  }

  clearShutdownDate() {
    this.shutdownDate = undefined;
  }

  private initPipController(pipController: PiPWindow.PiPController) {
    pipController.on('stateChange', (state: PiPWindow.PiPState) => {
      this.onStateChange(state);
    });
    pipController.on('controlPanelActionEvent', (event: PiPWindow.PiPActionEventType, status?: number) => {
      this.onActionEvent(event, status);
    });
  }

  private onStateChange(state: PiPWindow.PiPState) {
    switch (state) {
      case PiPWindow.PiPState.ABOUT_TO_STOP:
        if (this.pipState === PiPWindow.PiPState.STARTED) {
          this.videoPlayer.release();
        }
        break;
      case PiPWindow.PiPState.STOPPED:
        this.pipController?.off('stateChange');
        this.pipController?.off('controlPanelActionEvent');
        break;
      default:
        break;
    }
    this.pipState = state;
  }

  private onActionEvent(event: PiPWindow.PiPActionEventType, status?: number) {
    switch (event) {
      case 'playbackStateChanged':
        // 开始或停止视频
        if (status === 0) {
          // 停止视频
          this.videoPlayer.pause();
        } else if (status === 1) {
          // 播放视频
          this.videoPlayer.play();
        }
        break;
      default:
        break;
    }
  }

  private reset() {
    this.duration = 0;
    this.currTime = 0;
    this.isCasting = false;
    this.isPlaying = false;
    this.isLocking = false;
    this.isLandscape = false;
    this.isCtrlPanelShow = false;
    this.isSeeking = false;
    this.isSpeeding = false;
    this.isControlVolume = false;
    this.isControlBrightness = false;
    this.shutdownAfterComplete = false;
    this.playbackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
  }
}