import { fileIo } from '@kit.CoreFileKit';
import { avSession } from '@kit.AVSessionKit';
import { VideoInfoModel } from 'data_storage';
import { util } from '@kit.ArkTS';
import image from '@ohos.multimedia.image';

export class VideoCastViewModel {
  videoFile?: fileIo.File;
  avCastController?: avSession.AVCastController;

  constructor(controller: avSession.AVCastController) {
    this.avCastController = controller;
  }

  public async setCastVideo(videoInfo: VideoInfoModel, duration: number, startPosition: number) {
    try {
      this.videoFile = fileIo.openSync(videoInfo.videoPath);
    } catch (error) {
      console.info(`Failed to open video file ${this.videoFile?.path}. Cause: ${JSON.stringify(error)}`);
      return;
    }

    let mediaImg: image.PixelMap | undefined;
    try {
      mediaImg = await this.getMediaImage(videoInfo.thumbnailPath);
      const playItem: avSession.AVQueueItem = {
        itemId: videoInfo.id,
        description: {
          assetId: util.generateRandomUUID(),
          startPosition: startPosition,
          title: videoInfo.name,
          fdSrc: this.videoFile,
          mediaImage: mediaImg,
          duration: duration,
          mediaType: 'VIDEO',
        }
      };
      await this.avCastController?.prepare(playItem);
      await this.avCastController?.start(playItem);
    } catch (err) {
      console.error(`Failed to parepare and start av cast. Cause: ${JSON.stringify(err)}`);
    } finally {
      if (mediaImg) {
        await mediaImg.release();
      }
    }
  }

  public pause() {
    const command: avSession.AVCastControlCommand = { command: 'pause' };
    this.avCastController?.sendControlCommand(command)
      .catch((error: BusinessError) => {
        console.error(`Failed to send pause cast command. Cause: ${JSON.stringify(error)}`);
      });
  }

  public play() {
    const command: avSession.AVCastControlCommand = { command: 'play' };
    this.avCastController?.sendControlCommand(command)
      .catch((error: BusinessError) => {
        console.error(`Failed to send play cast command. Cause: ${JSON.stringify(error)}`);
      });
  }

  public seek(timeMs: number) {
    const command: avSession.AVCastControlCommand = { command: 'seek', parameter: timeMs };
    this.avCastController?.sendControlCommand(command)
      .catch((error: BusinessError) => {
        console.error(`Failed to send seek cast command. Cause: ${JSON.stringify(error)}`);
      });
  }

  public async releaseAVCast() {
    try {
      await fileIo.close(this.videoFile);
      await this.avCastController?.release();
    } catch (error) {
      console.error(`Failed to release AVCastController. Cause: ${JSON.stringify(error)}`);
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
}