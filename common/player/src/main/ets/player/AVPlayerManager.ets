import { media } from '@kit.MediaKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { audio } from '@kit.AudioKit';

export class AVPlayerManager {
  surfaceId?: string;
  videoFile?: fileIo.File;
  avPlayer?: media.AVPlayer;
  callbacks: Map<string, Function> = new Map();

  async initPlayer(surfaceId?: string): Promise<void> {
    this.surfaceId = surfaceId;
    if (!this.avPlayer) {
      try {
        this.avPlayer = await media.createAVPlayer();
        this.addEventListen();
      } catch (err) {
        console.error(`Failed to invoke createAVPlayer, error: ${JSON.stringify(err)}`);
      }
    }
  }

  async registerCallback(event: string, callback: Function): Promise<void> {
    this.callbacks.set(event, callback);
  }

  async setMediaAsset(videoPath: string): Promise<void> {
    if (this.avPlayer === undefined) {
      return;
    }
    try {
      if (this.avPlayer.state !== 'idle') {
        await this.avPlayer.reset();
      }
      this.videoFile = await fileIo.open(videoPath, fileIo.OpenMode.READ_WRITE);
      let url = `fd://${this.videoFile.fd}`;
      this.avPlayer.url = url;
    } catch (err) {
      console.error(`Failed to set fdsrc for avplayer, error: ${JSON.stringify(err)}`);
    }
  }

  async setAVMuted(isMuted: boolean) {
    try {
      await this.avPlayer?.setMediaMuted(media.MediaType.MEDIA_TYPE_AUD, isMuted);
      await this.avPlayer?.setMediaMuted(media.MediaType.MEDIA_TYPE_AUD, isMuted);
    } catch (error) {
      console.info(`Failed to invoke setMediaMuted. ${JSON.stringify(error)}`);
    }
  }

  async play(): Promise<void> {
    try {
      await this.avPlayer?.play();
    } catch (err) {
      console.error(`Failed to invoke avplayer play, error: ${JSON.stringify(err)}`);
    }
  }

  async pause(): Promise<void> {
    try {
      await this.avPlayer?.pause();
    } catch (err) {
      console.error(`Failed to invoke avplayer pause, error: ${JSON.stringify(err)}`);
    }
  }

  seek(timeMs: number): void {
    this.avPlayer?.seek(timeMs, media.SeekMode.SEEK_CLOSEST);
  }

  setSpeed(speed: media.PlaybackSpeed) {
    this.avPlayer?.setSpeed(speed);
  }

  getState(): media.AVPlayerState | undefined {
    return this.avPlayer?.state;
  }

  async reset(): Promise<void> {
    try {
      await this.avPlayer?.reset();
    } catch (err) {
      console.error(`Failed to invoke avplayer reset, error: ${JSON.stringify(err)}`);
    }
  }

  async release(): Promise<void> {
    if (this.avPlayer) {
      try {
        if (this.avPlayer.state === 'playing') {
          await this.avPlayer.pause();
        }
        await this.avPlayer.release();
      } catch (err) {
        console.error(`Failed to invoke avplayer release, error: ${JSON.stringify(err)}`);
      }
      this.avPlayer = undefined;
    }
    if (this.videoFile) {
      try {
        await fileIo.close(this.videoFile.fd);
      } catch (error) {
        console.error(`Failed to close file ${this.videoFile.path}. Cause: ${JSON.stringify(error)}`);
      }
      this.videoFile = undefined;
    }
  }

  private addEventListen() {
    if (this.avPlayer === undefined) {
      return;
    }
    this.avPlayer.on('error', (err: BusinessError) => {
      console.error(`AVPlayer error: ${JSON.stringify(err)}`);
    });
    this.avPlayer.on('durationUpdate', (duration: number) => {
      if (this.callbacks.has('durationUpdate')) {
        let callback = this.callbacks.get('durationUpdate') as (param: number) => void;
        callback(duration);
      }
      console.info(`AVPlayer duration update: ${duration}`);
    });
    this.avPlayer.on('seekDone', (timeMs: number) => {
      if (this.callbacks.has('seekDone')) {
        let callback = this.callbacks.get('seekDone') as (param: number) => void;
        callback(timeMs);
      }
    });
    this.avPlayer.on('timeUpdate', (timeMs: number) => {
      if (this.callbacks.has('timeUpdate')) {
        let callback = this.callbacks.get('timeUpdate') as (param: number) => void;
        callback(timeMs);
      }
    });
    this.avPlayer.on('stateChange', async (state: media.AVPlayerState, reason: media.StateChangeReason) => {
      if (this.callbacks.has('stateChange')) {
        let callback = this.callbacks.get('stateChange') as (param: media.AVPlayerState) => void;
        callback(state);
      }
      console.info(`AVPlayer state change: ${state} ${reason}`);
      switch (state) {
        case 'initialized':
          if (this.avPlayer === undefined) {
            return;
          }
          if (this.surfaceId) {
            this.avPlayer.surfaceId = this.surfaceId;
          }
          try {
            await this.avPlayer.prepare();
          } catch (err) {
            console.error(`Failed to invoke avplayer prepare, error: ${JSON.stringify(err)}`);
          }
          break;

        case 'prepared':
          if (this.avPlayer === undefined) {
            return;
          }
          this.avPlayer.audioInterruptMode = audio.InterruptMode.INDEPENDENT_MODE;
          try {
            await this.avPlayer.play();
          } catch (err) {
            console.error(`Failed to invoke avplyer play, error: ${JSON.stringify(err)}`);
          }
          break;

        default:
          break;
      }
    });
  }
}