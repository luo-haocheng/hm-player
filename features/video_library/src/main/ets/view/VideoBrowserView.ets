import { common } from '@kit.AbilityKit';
import { VideoListViewModel } from '../viewmodel/VideoListViewModel';
import { emitter } from '@kit.BasicServicesKit';
import { FolderInfoModel } from 'data_storage/src/main/ets/rdbms/FolderInfoModel';
import { VideoFolderListView } from './VideoFolderListView';
import { VideoItemViewModel } from '../viewmodel/VideoItemViewModel';
import { FolderItemViewModel } from '../viewmodel/FolderItemViewModel';
import { window } from '@kit.ArkUI';
import { MovingToDialog } from './MovingToDialog';
import { VideoInfoModel } from 'data_storage';

const ROOT_FOLDER = '/';
const SECRET_FOLDER = '/*/';
const IN_SECRET_FOLDER = 'InSecretFolder';
const DELETE_CHOICE_EVENT = 'DeleteChoice';
const SHARE_CHOICE_EVENT = 'ShareChoice';
const MOVE_CHOICE_EVENT = 'MoveChoice';
const MOVE_SECRET_EVENT = 'MoveSecret';
const CREATE_FOLDER_EVENT = 'CreateFolder';
const IMPORT_VIDEO_EVENT = 'ImportVideo';
const MOVE_FOLDER_EVENT = 'FolderVideo';
const MOVE_VIDEO_EVENT = 'MoveVideo';
const CURRENT_FOLDER = 'CurrentFolder';
const CHOICE_ALL_EVENT = 'ChoiceAll';
const SORT_VIDEO_FOLDER_EVENT = 'SortVideoFolder';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Builder
export function VideoBrowserBuilder() {
  VideoBrowserView();
}

@Component
export struct VideoBrowserView {
  @Consume(CURRENT_FOLDER) currFolder: string = ROOT_FOLDER;
  @Consume(IN_SECRET_FOLDER) inSecretFolder: boolean = false;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @State videoListVM: VideoListViewModel = new VideoListViewModel();
  private moveDialogController?: CustomDialogController;
  private createFolderCallback: Callback<emitter.EventData> = (event: emitter.EventData) => {
    if (event.data) {
      let folder = event.data['folder'] as string;
      let rowId = event.data['rowId'] as number;
      if (folder === this.videoListVM.folder) {
        this.videoListVM.updateFolderList(rowId);
      }
    }
  };
  private importVideoCallback: Callback<emitter.EventData> = (event: emitter.EventData) => {
    if (event.data) {
      let folder = event.data['folder'] as string;
      let rowId = event.data['rowId'] as number;
      if (folder === this.videoListVM.folder) {
        this.videoListVM.updateVideoList(rowId);
      }
    }
  };
  private moveVideoCallback: Callback<emitter.EventData> = (event: emitter.EventData) => {
    if (event.data) {
      let from = event.data['from'] as string;
      let to = event.data['to'] as string;
      let id = event.data['id'] as number;
      if (this.videoListVM.folder === from) {
        let idx = this.videoListVM.videoList.findIndex((item: VideoItemViewModel) => {
          return item.videoInfo.id === id;
        });
        if (idx !== -1) {
          this.videoListVM.videoList.splice(idx, 1);
        }
      }
      if (this.videoListVM.folder === to) {
        this.videoListVM.updateVideoList(id);
      }
    }
  };
  private moveFolderCallback: Callback<emitter.EventData> = (event: emitter.EventData) => {
    if (event.data) {
      let from = event.data['from'] as string;
      let to = event.data['to'] as string;
      let id = event.data['id'] as number;
      if (this.videoListVM.folder === from) {
        let idx = this.videoListVM.folderList.findIndex((item: FolderItemViewModel) => {
          return item.folderInfo.id === id;
        });
        if (idx !== -1) {
          this.videoListVM.folderList.splice(idx, 1);
        }
      }
      if (this.videoListVM.folder === to) {
        this.videoListVM.updateFolderList(id);
      }
    }
  };
  private choiceAllCallback: Callback<emitter.EventData> = (event: emitter.EventData) => {
    if (this.currFolder !== this.videoListVM.folder) {
      return;
    }
    if (event.data) {
      let choiceAll = event.data['choiceAll'] as boolean;
      this.videoListVM.videoList.forEach((item: VideoItemViewModel) => {
        item.isChoice = choiceAll;
      });
      this.videoListVM.folderList.forEach((item: FolderItemViewModel) => {
        item.isChoice = choiceAll;
      });
    }
  };
  private deleteChoiceCallback: Callback<emitter.EventData> = () => {
    if (this.currFolder !== this.videoListVM.folder) {
      return;
    }
    this.videoListVM.deleteChoiceItem();
  };
  private moveChoiceCallback: Callback<emitter.EventData> = () => {
    if (this.currFolder !== this.videoListVM.folder) {
      return;
    }
    let choiceVideoList: VideoInfoModel[] = [];
    this.videoListVM.videoList.forEach((item: VideoItemViewModel) => {
      if (item.isChoice) {
        choiceVideoList.push(item.videoInfo);
      }
    });
    let choiceFolderList: FolderInfoModel[] = [];
    this.videoListVM.folderList.forEach((item: FolderItemViewModel) => {
      if (item.isChoice) {
        choiceFolderList.push(item.folderInfo);
      }
    });
    if (choiceVideoList.length <= 0 && choiceFolderList.length <= 0) {
      return;
    }
    this.moveDialogController = new CustomDialogController({
      width: '100%',
      height: '60%',
      alignment: DialogAlignment.Bottom,
      builder: MovingToDialog({
        origFolder: this.videoListVM.folder,
        moveFolderList: choiceFolderList,
        moveVideoList: choiceVideoList
      }),
      offset: { dx: 0, dy: this.getUIContext().px2vp(this.bottomRectHeight) }
    });
    this.moveDialogController.open();
  };
  private shareChoiceCallback: Callback<emitter.EventData> = () => {
    if (this.currFolder !== this.videoListVM.folder) {
      return;
    }
    let shareVideos: VideoInfoModel[] = [];
    this.videoListVM.videoList.forEach((item: VideoItemViewModel) => {
      if (item.isChoice) {
        shareVideos.push(item.videoInfo);
      }
    });
    if (shareVideos.length <= 0) {
      return;
    }
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.videoListVM.shareVideos(shareVideos, context);
  };
  private moveSecretCallback: Callback<emitter.EventData> = async () => {
    if (this.currFolder !== this.videoListVM.folder) {
      return;
    }
    let choiceVideoList: VideoInfoModel[] = [];
    this.videoListVM.videoList.forEach((item: VideoItemViewModel) => {
      if (item.isChoice) {
        choiceVideoList.push(item.videoInfo);
      }
    });
    let choiceFolderList: FolderInfoModel[] = [];
    this.videoListVM.folderList.forEach((item: FolderItemViewModel) => {
      if (item.isChoice) {
        choiceFolderList.push(item.folderInfo);
      }
    });
    let moveFolder = this.currFolder.includes('*') ? ROOT_FOLDER : SECRET_FOLDER;
    for (let i = 0; i < choiceVideoList.length; ++i) {
      await this.videoListVM.moveVideo(choiceVideoList[i], moveFolder);
    }
    for (let i = 0; i < choiceFolderList.length; ++i) {
      await this.videoListVM.moveFolder(choiceFolderList[i], moveFolder);
    }
  };
  private sortItemCallback: Callback<emitter.EventData> = async () => {
    await this.videoListVM.sortFolderList(this.videoListVM.folderList);
    await this.videoListVM.sortVideoList(this.videoListVM.videoList);
  };

  aboutToAppear(): void {
    emitter.on(CREATE_FOLDER_EVENT, this.createFolderCallback);
    emitter.on(IMPORT_VIDEO_EVENT, this.importVideoCallback);
    emitter.on(MOVE_FOLDER_EVENT, this.moveFolderCallback);
    emitter.on(MOVE_VIDEO_EVENT, this.moveVideoCallback);
    emitter.on(CHOICE_ALL_EVENT, this.choiceAllCallback);
    emitter.on(MOVE_CHOICE_EVENT, this.moveChoiceCallback);
    emitter.on(MOVE_SECRET_EVENT, this.moveSecretCallback);
    emitter.on(SHARE_CHOICE_EVENT, this.shareChoiceCallback);
    emitter.on(DELETE_CHOICE_EVENT, this.deleteChoiceCallback);
    emitter.on(SORT_VIDEO_FOLDER_EVENT, this.sortItemCallback);
  }

  aboutToDisappear(): void {
    emitter.off(CREATE_FOLDER_EVENT, this.createFolderCallback);
    emitter.off(IMPORT_VIDEO_EVENT, this.importVideoCallback);
    emitter.off(MOVE_FOLDER_EVENT, this.moveFolderCallback);
    emitter.off(MOVE_VIDEO_EVENT, this.moveVideoCallback);
    emitter.off(CHOICE_ALL_EVENT, this.choiceAllCallback);
    emitter.off(MOVE_CHOICE_EVENT, this.moveChoiceCallback);
    emitter.off(MOVE_SECRET_EVENT, this.moveSecretCallback);
    emitter.off(SHARE_CHOICE_EVENT, this.shareChoiceCallback);
    emitter.off(DELETE_CHOICE_EVENT, this.deleteChoiceCallback);
    emitter.off(SORT_VIDEO_FOLDER_EVENT, this.sortItemCallback);
  }

  build() {
    NavDestination() {
      Flex({
        direction: FlexDirection.Column,
        justifyContent: FlexAlign.Start,
        alignItems: ItemAlign.Center
      }) {
        VideoFolderListView({
          folderList: this.videoListVM.folderList,
          videoList: this.videoListVM.videoList,
          videoListVM: this.videoListVM,
        });
      }
      .width('100%')
      .height('100%');
    }
    .hideBackButton(true)
    .backgroundColor($r('sys.color.background_secondary'))
    .onReady((navContext: NavDestinationContext) => {
      if (navContext.pathInfo.param !== undefined) {
        let folderInfo = navContext.pathInfo.param as FolderInfoModel;
        this.videoListVM.parent = folderInfo.parent;
        this.videoListVM.folder = folderInfo.path;
      }
      let context = this.getUIContext().getHostContext() as Context;
      this.videoListVM.init(this.videoListVM.folder, context);
    })
    .onActive(() => {
      this.inSecretFolder = this.videoListVM.folder.includes('*');
      this.currFolder = this.videoListVM.folder;
    })
    .onBackPressed(() => {
      if ([ROOT_FOLDER, SECRET_FOLDER].includes(this.currFolder)) {
        let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        context.windowStage.getMainWindow()
          .then((windowClass: window.Window) => {
            windowClass.minimize()
              .catch((err: BusinessError) => {
                console.error(`Failed to invoke Window.minize(). Cause: ${JSON.stringify(err)}`);
              });
          })
          .catch((err: BusinessError) => {
            console.error(`Failed to WindowStage.getMainWindow. Cause: ${JSON.stringify(err)}`);
          });
        return true;
      }
      return false;
    });
  }
}

