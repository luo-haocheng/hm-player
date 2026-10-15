import { AudioAlbumListViewModel } from '../viewmodel/AudioAlbumListViewModel';
import { AudioListInfo, AudioListType } from './AudioListView';
import { PlayListBoxView } from './PlayListBoxView';
import { PlayListItemViewModel, PlayListItemViewModelArray } from '../viewmodel/PlayListItemViewModel';
import { emitter } from '@kit.BasicServicesKit';
import { AudioInfoModel } from 'data_storage/src/main/ets/rdbms/AudioInfoModel';
import { ViewOptionValue } from 'data_storage';

const AUDIO_TAB_STACK = 'AudioTabStack';
const AUDIO_VIEW_OPTION = 'AudioViewOption';
const IMPORT_AUDIO_EVENT = 'ImportAudio';
const DELETE_AUDIO_EVENT = 'DeleteAudio';

@Component
export struct AudioAlbumListView {
  @State audioAlbumListVM: AudioAlbumListViewModel = new AudioAlbumListViewModel();
  private importAudioCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      this.audioAlbumListVM.updateAudio(audioInfo);
    }
  };
  private deleteAudioCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      this.audioAlbumListVM.removeAudio(audioInfo);
    }
  };

  async aboutToAppear(): Promise<void> {
    let context = this.getUIContext().getHostContext() as Context;
    await this.audioAlbumListVM.init(context);
    emitter.on(IMPORT_AUDIO_EVENT, this.importAudioCallback);
    emitter.on(DELETE_AUDIO_EVENT, this.deleteAudioCallback);
  }

  async aboutToDisappear(): Promise<void> {
    emitter.off(IMPORT_AUDIO_EVENT, this.importAudioCallback);
    emitter.off(DELETE_AUDIO_EVENT, this.deleteAudioCallback);
  }

  build() {
    ListView({ unknownAlbum: this.audioAlbumListVM.unknownAlbum, albumList: this.audioAlbumListVM.albumList });
  }
}

@Component
struct ListView {
  @ObjectLink albumList: PlayListItemViewModelArray;
  @ObjectLink unknownAlbum: PlayListItemViewModel | undefined;
  @Consume(AUDIO_TAB_STACK) audioTabStack: NavPathStack = new NavPathStack();
  @Consume(AUDIO_VIEW_OPTION) audioViewOptions: ViewOptionValue = ViewOptionValue.LIST_VIEW;

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      List() {
        if (this.unknownAlbum) {
          ListItem() {
            PlayListBoxView({ playlistVM: this.unknownAlbum })
              .onClick(() => {
                const audioListInfo: AudioListInfo = {
                  type: AudioListType.ALNUM_LIST,
                  name: null
                };
                this.audioTabStack.pushPath({ name: 'AudioList', param: audioListInfo });
              });
          };
        }

        ForEach(
          this.albumList,
          (item: PlayListItemViewModel) => {
            ListItem() {
              PlayListBoxView({ playlistVM: item })
                .onClick(() => {
                  const audioListInfo: AudioListInfo = {
                    type: AudioListType.ALNUM_LIST,
                    name: item.playListName
                  };
                  this.audioTabStack.pushPath({ name: 'AudioList', param: audioListInfo });
                });
            };
          },
          (item: string, index: number) => {
            index;
            return item;
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