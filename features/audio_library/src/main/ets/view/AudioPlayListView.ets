import { AudioPlayListViewModel } from '../viewmodel/AudioPlayListViewModel';
import { AudioListInfo, AudioListType } from './AudioListView';
import { PlayListBoxView } from './PlayListBoxView';
import { PlayListItemViewModel, PlayListItemViewModelArray } from '../viewmodel/PlayListItemViewModel';
import { emitter } from '@kit.BasicServicesKit';
import { PlayListInfoModel } from 'data_storage/src/main/ets/rdbms/PlayListInfoModel';
import { AudioInfoModel } from 'data_storage/src/main/ets/rdbms/AudioInfoModel';
import { ViewOptionValue } from 'data_storage';

const ALL_AUDIO = '*';
const FAVORITE_AUDIO = '**';
const AUDIO_TAB_STACK = 'AudioTabStack';
const AUDIO_VIEW_OPTION = 'AudioViewOption';
const IMPORT_AUDIO_EVENT = 'ImportAudio';
const DELETE_AUDIO_EVENT = 'DeleteAudio';
const SORT_PLAYLIST_EVENT = 'SortPlaylist';
const ADD_TO_PLAYLIST_EVENT = 'AddToPlaylist';
const CREATE_PLAYLIST_EVENT = 'CreatePlaylist';
const TOGGLE_FAVORITE_EVENT = 'ToggleFavorite';
const DELETE_FROM_PLAYLIST_EVENT = 'DeleteFromPlaylist';

@Component
export struct AudioPlayListView {
  @State audioPlaylistVM: AudioPlayListViewModel = new AudioPlayListViewModel();
  private createPlaylistCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const playlistInfo = eventData.data['info'] as PlayListInfoModel;
      this.audioPlaylistVM.updatePlayList(playlistInfo);
    }
  };
  private importAudioCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      this.audioPlaylistVM.updateAudio(audioInfo);
    }
  };
  private deleteAudioCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      this.audioPlaylistVM.removeAudio(audioInfo);
    }
  };
  private addToPlaylistCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      const playlistName = eventData.data['name'] as (string | null);
      this.audioPlaylistVM.addToPlaylist(audioInfo, playlistName);
    }
  };
  private deleteFromPlaylistCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      const playlistName = eventData.data['name'] as (string | null);
      this.audioPlaylistVM.deleteFromPlaylist(audioInfo, playlistName);
    }
  };
  private sortPlaylistCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    eventData;
    this.audioPlaylistVM.sortUserPlaylist();
  };
  private toggleFavoriteCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      this.audioPlaylistVM.toggleFavorite(audioInfo);
    }
  };

  aboutToAppear(): void {
    let context = this.getUIContext().getHostContext() as Context;
    this.audioPlaylistVM.init(context);
    emitter.on(IMPORT_AUDIO_EVENT, this.importAudioCallback);
    emitter.on(DELETE_AUDIO_EVENT, this.deleteAudioCallback);
    emitter.on(SORT_PLAYLIST_EVENT, this.sortPlaylistCallback);
    emitter.on(ADD_TO_PLAYLIST_EVENT, this.addToPlaylistCallback);
    emitter.on(CREATE_PLAYLIST_EVENT, this.createPlaylistCallback);
    emitter.on(TOGGLE_FAVORITE_EVENT, this.toggleFavoriteCallback);
    emitter.on(DELETE_FROM_PLAYLIST_EVENT, this.deleteFromPlaylistCallback);
  }

  aboutToDisappear(): void {
    emitter.off(IMPORT_AUDIO_EVENT, this.importAudioCallback);
    emitter.off(DELETE_AUDIO_EVENT, this.deleteAudioCallback);
    emitter.off(SORT_PLAYLIST_EVENT, this.sortPlaylistCallback);
    emitter.off(ADD_TO_PLAYLIST_EVENT, this.addToPlaylistCallback);
    emitter.off(CREATE_PLAYLIST_EVENT, this.createPlaylistCallback);
    emitter.off(TOGGLE_FAVORITE_EVENT, this.toggleFavoriteCallback);
    emitter.off(DELETE_FROM_PLAYLIST_EVENT, this.deleteFromPlaylistCallback);
  }

  build() {
    ListView({
      audioPlaylistVM: this.audioPlaylistVM,
      allPlaylist: this.audioPlaylistVM.allPlaylist,
      favoritePlaylist: this.audioPlaylistVM.favoritePlaylist,
      userPlaylistArray: this.audioPlaylistVM.userPlaylistArray,
    });
  }
}

@Component
struct ListView {
  @Link audioPlaylistVM: AudioPlayListViewModel;
  @ObjectLink allPlaylist: PlayListItemViewModel;
  @ObjectLink favoritePlaylist: PlayListItemViewModel;
  @ObjectLink userPlaylistArray: PlayListItemViewModelArray;
  @Consume(AUDIO_TAB_STACK) audioTabStack: NavPathStack = new NavPathStack();
  @Consume(AUDIO_VIEW_OPTION) audioViewOptions: ViewOptionValue = ViewOptionValue.LIST_VIEW;
  private selectedIdx: number = -1;

  @Builder
  longPressMenuBuilder() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center,
    }) {
      Row() {
        Text('编辑')
          .fontSize(14)
          .fontColor($r('sys.color.font_primary'));
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(() => {
        // todo
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
      .onClick(() => {
        this.audioPlaylistVM.deleteUserPlaylist(this.selectedIdx);
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
        ListItem() {
          PlayListBoxView({ playlistVM: this.allPlaylist });
        }
        .onClick(() => {
          const audioListInfo: AudioListInfo = {
            type: AudioListType.PLAY_LIST,
            name: ALL_AUDIO
          };
          this.audioTabStack.pushPath({ name: 'AudioList', param: audioListInfo });
        });

        ListItem() {
          PlayListBoxView({ playlistVM: this.favoritePlaylist });
        }
        .onClick(() => {
          const audioListInfo: AudioListInfo = {
            type: AudioListType.PLAY_LIST,
            name: FAVORITE_AUDIO
          };
          this.audioTabStack.pushPath({ name: 'AudioList', param: audioListInfo });
        });

        ForEach(
          this.userPlaylistArray,
          (item: PlayListItemViewModel, index: number) => {
            ListItem() {
              PlayListBoxView({ playlistVM: item })
                .onClick(() => {
                  const audioListInfo: AudioListInfo = {
                    type: AudioListType.PLAY_LIST,
                    name: item.playListName
                  };
                  this.audioTabStack.pushPath({ name: 'AudioList', param: audioListInfo });
                });
            }
            .bindContextMenu(
              this.longPressMenuBuilder,
              ResponseType.LongPress,
              {
                previewBorderRadius: 12,
                placement: Placement.Bottom,
                preview: MenuPreviewMode.IMAGE,
                aboutToAppear: () => {
                  this.selectedIdx = index;
                }
              }
            );
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