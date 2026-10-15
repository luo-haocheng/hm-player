import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';
import { AudioItemViewModelList, AudioListViewModel } from '../viewmodel/AudioListViewModel';
import { AudioBoxView } from './AudioBoxView';
import { emitter } from '@kit.BasicServicesKit';
import { AudioInfoModel } from 'data_storage/src/main/ets/rdbms/AudioInfoModel';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { AddToPlaylistDialog } from './AddToPlaylistDialog';
import { AudioEditDialog } from './AudioEditDialog';
import { ViewOptionValue } from 'data_storage';

const ALL_AUDIO = '*';
const FAVORITE_AUDIO = '**';
const AUDIO_LIST_INFO = 'AudioListInfo';
const AUDIO_VIEW_OPTION = 'AudioViewOption';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';
const AUDIO_PLAYER_VM = 'AudioPlayerVM';
const MULTI_CHOICE = 'MultiChoice';
const CHOICE_ALL = 'ChoiceAll';
const SORT_AUDIO_EVENT = 'SortAudio';
const CHOICE_ALL_EVENT = 'ChoiceAll';
const IMPORT_AUDIO_EVENT = 'ImportAudio';
const DELETE_CHOICE_EVENT = 'DeleteChoice';
const TOGGLE_FAVORITE_EVENT = 'ToggleFavorite';
const ADD_PLAYLIST_CHOICE_EVENT = 'AddPlaylistChoice';
const DELETE_PLAYLIST_CHOICE_EVENT = 'DeletePlaylistChoice';

export enum AudioListType {
  PLAY_LIST = 'PlayList',
  ALNUM_LIST = 'AlbumList',
  ARTIST_LIST = 'ArtistList',
}

export class AudioListInfo {
  type: AudioListType = AudioListType.PLAY_LIST;
  name: string | null = null;
}

@Builder
export function AudioListBuilder() {
  AudioListView();
}

@Component
export struct AudioListView {
  @State audioListVM: AudioListViewModel = new AudioListViewModel();
  @Consume(CHOICE_ALL) choiceAll: boolean = true;
  @Consume(AUDIO_LIST_INFO) currAudioList?: AudioListInfo = undefined;
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();
  private addPlaylistDialogController?: CustomDialogController;
  private importAudioCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      this.audioListVM.updateAudio(audioInfo);
    }
  };
  private choiceAllCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    eventData;
    this.audioListVM.audioList.forEach((item: AudioItemViewModel) => {
      item.isChoice = this.choiceAll;
    });
    this.choiceAll = !this.choiceAll;
  };
  private deleteChoiceCallback: Callback<emitter.EventData> = async (eventData: emitter.EventData) => {
    eventData;
    const choiceAudioArr: AudioInfoModel[] = [];
    this.audioListVM.audioList.forEach((item: AudioItemViewModel) => {
      if (item.isChoice) {
        choiceAudioArr.push(item.audioInfo);
      }
    });
    const context = this.getUIContext().getHostContext() as Context;
    for (let i = 0; i < choiceAudioArr.length; ++i) {
      await this.audioPlayerVM.deleteAudio(choiceAudioArr[i], context);
      await this.audioListVM.deleteAudio(choiceAudioArr[i]);
    }
  };
  private addToPlaylistCallback: Callback<emitter.EventData> = async (eventData: emitter.EventData) => {
    eventData;
    const choiceAudioArr: AudioInfoModel[] = [];
    this.audioListVM.audioList.forEach((item: AudioItemViewModel) => {
      if (item.isChoice) {
        choiceAudioArr.push(item.audioInfo);
      }
    });
    this.addPlaylistDialogController = new CustomDialogController({
      width: '100%',
      height: '60%',
      alignment: DialogAlignment.Bottom,
      builder: AddToPlaylistDialog({ audioInfoList: choiceAudioArr }),
      offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
    });
    this.addPlaylistDialogController.open();
  };
  private deleteFromPlaylistCallback: Callback<emitter.EventData> = async (eventData: emitter.EventData) => {
    eventData;
    const choiceAudioArr: AudioInfoModel[] = [];
    this.audioListVM.audioList.forEach((item: AudioItemViewModel) => {
      if (item.isChoice) {
        choiceAudioArr.push(item.audioInfo);
      }
    });
    for (let i = 0; i < choiceAudioArr.length; ++i) {
      this.audioListVM.deleteFromPlaylist(choiceAudioArr[i]);
    }
  };
  private sortAudioCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    eventData;
    this.audioListVM.sortAudioList();
  };
  private toggleFavoriteCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      this.audioListVM.toggleFavorite(audioInfo);
    }
  };

  aboutToAppear(): void {
    emitter.on(DELETE_PLAYLIST_CHOICE_EVENT, this.deleteFromPlaylistCallback);
    emitter.on(ADD_PLAYLIST_CHOICE_EVENT, this.addToPlaylistCallback);
    emitter.on(TOGGLE_FAVORITE_EVENT, this.toggleFavoriteCallback);
    emitter.on(DELETE_CHOICE_EVENT, this.deleteChoiceCallback);
    emitter.on(IMPORT_AUDIO_EVENT, this.importAudioCallback);
    emitter.on(CHOICE_ALL_EVENT, this.choiceAllCallback);
    emitter.on(SORT_AUDIO_EVENT, this.sortAudioCallback);
  }

  aboutToDisappear(): void {
    emitter.off(DELETE_PLAYLIST_CHOICE_EVENT, this.deleteFromPlaylistCallback);
    emitter.off(ADD_PLAYLIST_CHOICE_EVENT, this.addToPlaylistCallback);
    emitter.off(TOGGLE_FAVORITE_EVENT, this.toggleFavoriteCallback);
    emitter.on(DELETE_CHOICE_EVENT, this.deleteChoiceCallback);
    emitter.off(DELETE_CHOICE_EVENT, this.deleteChoiceCallback);
    emitter.off(IMPORT_AUDIO_EVENT, this.importAudioCallback);
    emitter.off(CHOICE_ALL_EVENT, this.choiceAllCallback);
    emitter.off(SORT_AUDIO_EVENT, this.sortAudioCallback);
  }

  build() {
    NavDestination() {
      ListView({ audioListVM: this.audioListVM, audioList: this.audioListVM.audioList });
    }
    .backgroundColor('#F1F3F5')
    .hideBackButton(true)
    .onWillDisappear(() => {
      this.currAudioList = undefined;
    })
    .onReady(async (navDesContext: NavDestinationContext) => {
      let context = this.getUIContext().getHostContext() as Context;
      await this.audioListVM.init(context);
      if (navDesContext.pathInfo.param) {
        this.audioListVM.audioListInfo = navDesContext.pathInfo.param as AudioListInfo;
        this.currAudioList = this.audioListVM.audioListInfo;
        this.audioListVM.loadAudioList();
      }
    });
  }
}

@Component
struct ListView {
  @Link audioListVM: AudioListViewModel;
  @ObjectLink audioList: AudioItemViewModelList;
  @Consume(MULTI_CHOICE) multiChoice: boolean = false;
  @Consume(CHOICE_ALL) choiceAll: boolean = true;
  @Consume(AUDIO_VIEW_OPTION) audioViewOptions: ViewOptionValue = ViewOptionValue.LIST_VIEW;
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();
  private selectedItem?: AudioItemViewModel;
  private audioEditDialogController?: CustomDialogController;
  private addPlaylistDialogController?: CustomDialogController;
  private isAllChoice: Callback<void> = () => {
    const choiceAll = this.audioListVM.audioList.find((item: AudioItemViewModel) => {
      return !item.isChoice;
    });
    this.choiceAll = (choiceAll !== undefined);
  };

  @Builder
  longPressMenuBuilder() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center,
    }) {
      Row() {
        Text('添加到歌单')
          .fontSize(14)
          .fontColor($r('sys.color.font_primary'));
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(() => {
        setTimeout(() => {
          if (this.selectedItem) {
            this.addPlaylistDialogController = new CustomDialogController({
              width: '100%',
              height: '60%',
              alignment: DialogAlignment.Bottom,
              builder: AddToPlaylistDialog({ audioInfoList: [this.selectedItem.audioInfo] }),
              offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
            });
            this.addPlaylistDialogController.open();
          }
        }, 200);
      });

      Divider()
        .vertical(false)
        .strokeWidth(0.5);

      if (
        this.audioListVM.audioListInfo.type === AudioListType.PLAY_LIST &&
          ![ALL_AUDIO, FAVORITE_AUDIO].includes(this.audioListVM.audioListInfo.name ?? '')
      ) {
        Row() {
          Text('从歌单中移除')
            .fontSize(14)
            .fontColor($r('sys.color.font_primary'));
        }
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .onClick(() => {
          if (this.selectedItem) {
            this.audioListVM.deleteFromPlaylist(this.selectedItem.audioInfo);
          }
        });

        Divider()
          .vertical(false)
          .strokeWidth(0.5);
      }

      Row() {
        Text('编辑')
          .fontSize(14)
          .fontColor($r('sys.color.font_primary'));
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(async () => {
        setTimeout(() => {
          if (this.selectedItem) {
            this.audioEditDialogController = new CustomDialogController({
              width: '100%',
              height: '80%',
              alignment: DialogAlignment.Bottom,
              builder: AudioEditDialog({ audioItem: this.selectedItem }),
              offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
            });
            this.audioEditDialogController.open();
          }
        }, 200);
      });

      Divider()
        .vertical(false)
        .strokeWidth(0.5);

      Row() {
        Text('删除')
          .fontSize(14)
          .fontColor(Color.Red);
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(async () => {
        const context = this.getUIContext().getHostContext() as Context;
        if (this.selectedItem) {
          await this.audioPlayerVM.deleteAudio(this.selectedItem.audioInfo, context);
          await this.audioListVM.deleteAudio(this.selectedItem.audioInfo);
        }
      });
    }
    .width(160)
    .padding({ left: 16, right: 16 });
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      List() {
        ForEach(
          this.audioList,
          (item: AudioItemViewModel) => {
            ListItem() {
              AudioBoxView({ audioItem: item, isAllChoice: this.isAllChoice });
            }
            .bindContextMenu(
              this.longPressMenuBuilder,
              ResponseType.LongPress,
              {
                previewBorderRadius: 12,
                placement: Placement.Bottom,
                preview: MenuPreviewMode.IMAGE,
                aboutToAppear: () => {
                  this.selectedItem = item;
                }
              })
            .onClick(async () => {
              if (this.multiChoice) {
                item.isChoice = !item.isChoice;
              } else {
                const context = this.getUIContext().getHostContext() as Context;
                await this.audioPlayerVM.init(context);
                this.audioPlayerVM.updatePlaylist(this.audioList, item);
                await this.audioPlayerVM.setAudioAsset(item.audioInfo, context);
              }
            });
          },
          (item: AudioItemViewModel) => {
            return item.audioInfo.id.toString();
          }
        );
      }
      .width('100%')
      .height('100%')
      .contentEndOffset(72)
      .contentStartOffset(8)
      .scrollBar(BarState.Off)
      .backgroundColor($r('sys.color.background_secondary'))
      .divider({ strokeWidth: 8, color: $r('sys.color.background_secondary') })
      .lanes(this.audioViewOptions === ViewOptionValue.LIST_VIEW ? 1 : 2, 8);
    }
    .width('100%')
    .height('100%');
  }
}