import { avSession as AVSessionMananger } from '@kit.AVSessionKit';
import { media } from '@kit.MediaKit';
import image from '@ohos.multimedia.image';
import { util } from '@kit.ArkTS';
import { VideoInfoModel } from 'data_storage/src/main/ets/rdbms/VideoInfoModel';
import { AudioInfoModel } from 'data_storage/src/main/ets/rdbms/AudioInfoModel';
import { AudioRepeatMode } from 'data_storage';

export class MediaSessionManager {
  private session?: AVSessionMananger.AVSession;
  private static sessionMgr?: MediaSessionManager;
  private callbacks: Map<string, Function> = new Map();

  static getInstance(): MediaSessionManager {
    if (!MediaSessionManager.sessionMgr) {
      MediaSessionManager.sessionMgr = new MediaSessionManager();
    }
    return MediaSessionManager.sessionMgr;
  }

  getSessionType(): AVSessionMananger.AVSessionType | undefined {
    if (this.session) {
      return this.session.sessionType;
    }
    return undefined;
  }

  async getAVCastController(): Promise<AVSessionMananger.AVCastController | undefined> {
    if (this.session) {
      try {
        return await this.session.getAVCastController();
      } catch (error) {
        console.error(`Failed to invoke getAVCastController. Cause: ${JSON.stringify(error)}`);
        return undefined;
      }
    }
    return undefined;
  }

  async stopCasting() {
    try {
      await this.session?.stopCasting();
    } catch (error) {
      console.info(`Failed to invoke stopCasting. Cause: ${JSON.stringify(error)}`);
    }
  }

  async initAudioSession(context: Context): Promise<void> {
    if (this.session && this.session.sessionType === 'video') {
      try {
        await this.session.destroy();
        this.session = undefined;
      } catch (error) {
        return;
      }
    }
    if (!this.session) {
      try {
        let sessionName = util.generateRandomUUID();
        this.session = await AVSessionMananger.createAVSession(context, sessionName, 'audio');
      } catch (error) {
        console.error(`Failed to create avsession. Cause: ${JSON.stringify(error)}`);
        return;
      }
      try {
        this.registerAudioCtrlCmd();
      } catch (error) {
        console.error(`Failed to register avsession control command. Cuase: ${JSON.stringify(error)}`);
        return;
      }

      try {
        await this.session.activate();
      } catch (error) {
        console.error(`Failed to invoke avsession.activate. Cause: ${JSON.stringify(error)}`);
        return;
      }

      try {
        await this.session.setExtras(({ requireAbilityList: ['url-cast'], }));
      } catch (error) {
        console.error(`Failed to invoke avsession.setExtras. Cause: ${JSON.stringify(error)}`);
        return;
      }
    }
  }

  async setAudioAsset(context: Context, audioInfo: AudioInfoModel, lyricsText?: string) {
    if (this.session) {
      let duration = -1;
      let mediaImg: image.PixelMap | undefined;
      try {
        if (audioInfo.coverPath) {
          mediaImg = await this.getMediaImage(audioInfo.coverPath);
        } else {
          mediaImg = await this.getDefaultImage(context);
        }
        if (audioInfo.metadata) {
          duration = await this.getMediaDuration(audioInfo.metadata);
        }
        const filter = AVSessionMananger.ProtocolType.TYPE_CAST_PLUS_STREAM | AVSessionMananger.ProtocolType.TYPE_DLNA;
        const metadata: AVSessionMananger.AVMetadata = {
          assetId: util.generateRandomUUID(),
          title: audioInfo.title,
          mediaImage: mediaImg,
          duration: duration,
          filter: filter,
        };
        if (audioInfo.artist) {
          metadata.artist = audioInfo.artist;
        } else {
          metadata.artist = '未知歌手';
        }
        if (lyricsText) {
          metadata.lyric = lyricsText;
        }
        await this.session.setAVMetadata(metadata);
      } catch (error) {
        console.error(`Failed to invoke avsession.setAVMetadata. Cause: ${JSON.stringify(error)}`);
        return;
      } finally {
        if (mediaImg) {
          await mediaImg.release();
        }
      }
    }
  }

  async initVideoSession(context: Context): Promise<void> {
    if (this.session && this.session.sessionType === 'audio') {
      try {
        await this.session.destroy();
        this.session = undefined;
      } catch (error) {
        return;
      }
    }
    if (!this.session) {
      try {
        let sessionName = util.generateRandomUUID();
        this.session = await AVSessionMananger.createAVSession(context, sessionName, 'video');
      } catch (error) {
        console.error(`Failed to create avsession. Cause: ${JSON.stringify(error)}`);
        return;
      }
      try {
        this.registerVideoCtrlCmd();
      } catch (error) {
        console.error(`Failed to register avsession control command. Cuase: ${JSON.stringify(error)}`);
        return;
      }

      try {
        await this.session.activate();
      } catch (error) {
        console.error(`Failed to invoke avsession.activate. Cause: ${JSON.stringify(error)}`);
        return;
      }

      try {
        await this.session.setExtras(({ requireAbilityList: ['url-cast'], }));
      } catch (error) {
        console.error(`Failed to invoke avsession.setExtras. Cause: ${JSON.stringify(error)}`);
        return;
      }
    }
  }

  async setVideoAsset(info: VideoInfoModel, timeMs: number, state: media.AVPlayerState): Promise<void> {
    if (this.session) {
      let duration = -1;
      let mediaImg: image.PixelMap | undefined;
      try {
        mediaImg = await this.getMediaImage(info.thumbnailPath);
        duration = await this.getMediaDuration(info.metadata);
        const filter = AVSessionMananger.ProtocolType.TYPE_CAST_PLUS_STREAM | AVSessionMananger.ProtocolType.TYPE_DLNA;
        let metadata: AVSessionMananger.AVMetadata = {
          assetId: util.generateRandomUUID(),
          mediaImage: mediaImg,
          duration: duration,
          title: info.name,
          filter: filter,
        };
        await this.session.setAVMetadata(metadata);
        await this.updatePlayState(timeMs, state);
      } catch (error) {
        console.error(`Failed to invoke avsession.setAVMetadata. Cause: ${JSON.stringify(error)}`);
        return;
      } finally {
        if (mediaImg) {
          await mediaImg.release();
        }
      }
    }
  }

  async updateElapsedTime(timeMs: number) {
    try {
      let playbackState: AVSessionMananger.AVPlaybackState = {
        position: {
          elapsedTime: timeMs,
          updateTime: new Date().getTime()
        }
      };
      await this.session?.setAVPlaybackState(playbackState);
    } catch (error) {
      console.error(`Failed to update avsession elapsed time. Cause: ${JSON.stringify(error)}`);
      return;
    }
  }

  async updatePlayState(timeMs: number, state: media.AVPlayerState): Promise<void> {
    let playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_ERROR;
    switch (state) {
      case 'initialized':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_INITIAL;
        break;
      case 'prepared':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_PREPARE;
        break;
      case 'playing':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_PLAY;
        break;
      case 'paused':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_PAUSE;
        break;
      case 'stopped':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_STOP;
        break;
      case 'completed':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_COMPLETED;
        break;
      case 'released':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_RELEASED;
        break;
      case 'idle':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_IDLE;
        break;
      case 'error':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_ERROR;
        break;
      default:
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_ERROR;
        break;
    }
    try {
      let playbackState: AVSessionMananger.AVPlaybackState = {
        state: playState,
        position: {
          elapsedTime: timeMs,
          updateTime: new Date().getTime()
        }
      };
      await this.session?.setAVPlaybackState(playbackState);
    } catch (error) {
      console.error(`Failed to update avsession play state. Cause: ${JSON.stringify(error)}`);
      return;
    }
  }

  async updateLoopMode(timeMs: number, repeatMode: AudioRepeatMode) {
    let loopMode = AVSessionMananger.LoopMode.LOOP_MODE_SINGLE;
    switch (repeatMode) {
      case AudioRepeatMode.SINGLE_REPEAT:
        loopMode = AVSessionMananger.LoopMode.LOOP_MODE_SINGLE;
        break;
      case AudioRepeatMode.LIST_REPEAT:
        loopMode = AVSessionMananger.LoopMode.LOOP_MODE_LIST;
        break;
      case AudioRepeatMode.SHUFFLE:
        loopMode = AVSessionMananger.LoopMode.LOOP_MODE_SHUFFLE;
        break;
    }
    try {
      let playbackState: AVSessionMananger.AVPlaybackState = {
        loopMode: loopMode,
        position: {
          elapsedTime: timeMs,
          updateTime: new Date().getTime()
        }
      };
      await this.session?.setAVPlaybackState(playbackState);
    } catch (error) {
      console.error(`Failed to update avsession loop mode. Cause: ${JSON.stringify(error)}`);
      return;
    }
  }

  async updateFavorite(timeMs: number, isFavorite: boolean) {
    try {
      let playbackState: AVSessionMananger.AVPlaybackState = {
        isFavorite: isFavorite,
        position: {
          elapsedTime: timeMs,
          updateTime: new Date().getTime()
        }
      };
      await this.session?.setAVPlaybackState(playbackState);
    } catch (error) {
      console.error(`Failed to update avsession loop mode. Cause: ${JSON.stringify(error)}`);
      return;
    }
  }

  async updatePlayPosition(timeMs: number): Promise<void> {
    try {
      let playbackState: AVSessionMananger.AVPlaybackState = {
        position: {
          elapsedTime: timeMs,
          updateTime: new Date().getTime()
        }
      };
      await this.session?.setAVPlaybackState(playbackState);
    } catch (error) {
      console.error(`Failed to update avsession play position. Cause: ${JSON.stringify(error)}`);
      return;
    }
  }

  async updatePlaySpeed(timeMs: number, playSpeed: number): Promise<void> {
    try {
      let playbackState: AVSessionMananger.AVPlaybackState = {
        position: {
          elapsedTime: timeMs,
          updateTime: new Date().getTime()
        },
        speed: playSpeed
      };
      await this.session?.setAVPlaybackState(playbackState);
    } catch (error) {
      console.error(`Failed to update avsession play speed. Cause: ${JSON.stringify(error)}`);
      return;
    }
  }

  async release(): Promise<void> {
    try {
      if (this.session) {
        await this.session.destroy();
        this.session = undefined;
      }
    } catch (error) {
      console.error(`Failed to invoke avsession.destroy. Cause: ${JSON.stringify(error)}`);
    }
  }

  async registerCallback(event: string, callback: Function) {
    this.callbacks.set(event, callback);
  }

  private registerAudioCtrlCmd() {
    try {
      this.session?.on('play', () => {
        if (this.callbacks.has('play')) {
          const callback = this.callbacks.get('play') as () => void;
          callback();
        }
      });
      this.session?.on('pause', () => {
        if (this.callbacks.has('pause')) {
          const callback = this.callbacks.get('pause') as () => void;
          callback();
        }
      });
      this.session?.on('seek', (timeMs: number) => {
        if (this.callbacks.has('seek')) {
          const callback = this.callbacks.get('seek') as (timeMs: number) => void;
          callback(timeMs);
        }
      });
      this.session?.on('playNext', () => {
        if (this.callbacks.has('playNext')) {
          const callback = this.callbacks.get('playNext') as () => void;
          callback();
        }
      });
      this.session?.on('playPrevious', () => {
        if (this.callbacks.has('playPrevious')) {
          const callback = this.callbacks.get('playPrevious') as () => void;
          callback();
        }
      });
      this.session?.on('setLoopMode', (loopMode: AVSessionMananger.LoopMode) => {
        if (this.callbacks.has('setLoopMode')) {
          const callback = this.callbacks.get('setLoopMode') as (loopMode: AVSessionMananger.LoopMode) => void;
          callback(loopMode);
        }
      });
      this.session?.on('toggleFavorite', (assetId: string) => {
        if (this.callbacks.has('toggleFavorite')) {
          const callback = this.callbacks.get('toggleFavorite') as (assetId: string) => void;
          callback(assetId);
        }
      });
    } catch (error) {
      throw Error(error);
    }
  }

  private registerVideoCtrlCmd() {
    try {
      this.session?.on('play', () => {
        if (this.callbacks.has('play')) {
          const callback = this.callbacks.get('play') as () => void;
          callback();
        }
      });
      this.session?.on('pause', () => {
        if (this.callbacks.has('pause')) {
          const callback = this.callbacks.get('pause') as () => void;
          callback();
        }
      });
      this.session?.on('seek', (timeMs: number) => {
        if (this.callbacks.has('seek')) {
          const callback = this.callbacks.get('seek') as (timeMs: number) => void;
          callback(timeMs);
        }
      });
      this.session?.on('rewind', (timeS?: number) => {
        if (this.callbacks.has('rewind')) {
          const callback = this.callbacks.get('rewind') as (timeS?: number) => void;
          callback(timeS);
        }
      });
      this.session?.on('fastForward', (timeS?: number) => {
        if (this.callbacks.has('fastForward')) {
          const callback = this.callbacks.get('fastForward') as (timeS?: number) => void;
          callback(timeS);
        }
      });
      this.session?.on('outputDeviceChange', (state, device) => {
        if (this.callbacks.has('outputDeviceChange')) {
          const callback = this.callbacks.get('outputDeviceChange') as
            (state: AVSessionMananger.ConnectionState, device: AVSessionMananger.OutputDeviceInfo) => void;
          callback(state, device);
        }
      });
      if (this.callbacks.has('playPrevious')) {
        this.session?.on('playPrevious', () => {
          if (this.callbacks.has('playPrevious')) {
            const callback = this.callbacks.get('playPrevious') as () => void;
            callback();
          }
        });
      }
      if (this.callbacks.has('playNext')) {
        this.session?.on('playNext', () => {
          if (this.callbacks.has('playNext')) {
            const callback = this.callbacks.get('playNext') as () => void;
            callback();
          }
        });
      }
    } catch (error) {
      throw Error(error);
    }
  }

  private async getMediaImage(thumbnailPath: string): Promise<image.PixelMap | undefined> {
    let imageSource: image.ImageSource | undefined;
    let mediaImg: image.PixelMap | undefined;
    try {
      imageSource = image.createImageSource(thumbnailPath);
      mediaImg = await imageSource.createPixelMap();
    } catch (error) {
      console.error(`Failed to create preview image. Cause: ${JSON.stringify(error)}`);
    } finally {
      if (imageSource) {
        imageSource.release();
      }
    }
    return mediaImg;
  }

  private async getDefaultImage(context: Context): Promise<image.PixelMap | undefined> {
    let imageSource: image.ImageSource | undefined;
    let mediaImg: image.PixelMap | undefined;
    try {
      const rawFd = await context.resourceManager.getRawFd('audio_default.jpg');
      imageSource = image.createImageSource(rawFd);
      mediaImg = await imageSource.createPixelMap();
    } catch (error) {
      console.error(`Failed to create default music cover. Cause: ${JSON.stringify(error)}`);
    } finally {
      if (imageSource) {
        imageSource.release();
      }
    }
    return mediaImg;
  }

  private async getMediaDuration(metadataStr: string): Promise<number> {
    let metadata = JSON.parse(metadataStr) as media.AVMetadata;
    let duration = metadata.duration ? parseInt(metadata.duration) : 0;
    return duration;
  }
}