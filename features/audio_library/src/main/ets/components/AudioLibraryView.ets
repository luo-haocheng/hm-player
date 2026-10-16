import { AudioLibraryViewModel } from '../viewmodel/AudioLibraryViewModel';
import { AudioAlbumListView } from '../view/AudioAlbumListView';
import { AudioArtistListView } from '../view/AudioArtistListView';
import { AudioBottomBar } from '../view/AudioBottomBar';
import { AudioListInfo, AudioListType } from '../view/AudioListView';
import { AudioPlayListView } from '../view/AudioPlayListView';
import { emitter } from '@kit.BasicServicesKit';
import { SortModeValue, SortRuleValue, ViewOptionValue } from 'data_storage';

const ALL_AUDIO = '*';
const FAVORITE_AUDIO = '**';
const INVALID_VALUES = '/\\:*?"<>|';
const AUDIO_VIEW_OPTION = 'AudioViewOption';
const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';
const CHOICE_ALL = 'ChoiceAll';
const CHOICE_COUNT = 'ChoiceCount';
const MULTI_CHOICE = 'MultiChoice';
const CHOICE_ALL_EVENT = 'ChoiceAll';
const DELETE_CHOICE_EVENT = 'DeleteChoice';
const ADD_PLAYLIST_CHOICE_EVENT = 'AddPlaylistChoice';
const DELETE_PLAYLIST_CHOICE_EVENT = 'DeletePlaylistChoice';
const AUDIO_LIST_INFO = 'AudioListInfo';
const AUDIO_TAB_STACK = 'AudioTabStack';
const IMPORT_OPTS: ImportOption[] = [
  { icon: $r('app.media.plus'), text: '新建歌单', color: Color.Green },
  { icon: $r('app.media.music'), text: '音频文件导入', color: Color.Blue },
  { icon: $r('app.media.folder'), text: '文件管理导入', color: Color.Orange },
  { icon: $r('app.media.download_folder'), text: '下载目录导入', color: Color.Red },
];

interface ImportOption {
  color: ResourceColor,
  icon: Resource,
  text: string
};

@Component
export struct AudioLibraryView {
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @Provide(CHOICE_ALL) choiceAll: boolean = true;
  @Provide(CHOICE_COUNT) choiceCount: number = 0;
  @Provide(MULTI_CHOICE) multiChoice: boolean = false;
  @Provide(AUDIO_LIST_INFO) currAudioList?: AudioListInfo = undefined;
  @Provide(AUDIO_TAB_STACK) audioTabStack: NavPathStack = new NavPathStack();
  @Provide(AUDIO_VIEW_OPTION) audioViewOptions: ViewOptionValue = ViewOptionValue.LIST_VIEW;
  @State selectedIndex: number = 0;
  @State invalidName: boolean = false;
  @State isSortExpand: boolean = false;
  @State audioLibVM: AudioLibraryViewModel = new AudioLibraryViewModel();
  private newPlaylistName?: string;
  private importDialogId: number = -1;
  private createPlaylistDialogId: number = 0;
  private multiChoiceDialogId: number = 0;

  async aboutToAppear(): Promise<void> {
    let context = this.getUIContext().getHostContext() as Context;
    await this.audioLibVM.init(context);
    this.audioViewOptions = await this.audioLibVM.getViewOptions();
  }

  @Builder
  importOptionBuilder(option: ImportOption) {
    Row({ space: 12 }) {
      Image(option.icon)
        .width(30)
        .aspectRatio(1)
        .fillColor(option.color)
        .backgroundColor(Color.Transparent);

      Text(option.text)
        .fontSize(16)
        .fontWeight(FontWeight.Normal)
        .fontColor($r('sys.color.font_primary'));

      Blank();

      Image($r('app.media.chevron_right'))
        .width(12)
        .aspectRatio(1)
        .backgroundColor(Color.Transparent)
        .fillColor($r('sys.color.font_primary'));
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 });
  }

  @Builder
  importDialogBuilder() {
    Column() {
      Row() {
        Text('选择导入方式')
          .fontSize(20)
          .fontWeight(FontWeight.Bold);

        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Image($r('app.media.xmark'))
            .width(20)
            .aspectRatio(1)
            .fillColor($r('sys.color.font_primary'));
        }
        .padding(8)
        .backgroundColor($r('sys.color.button_background_color_transparent'))
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
        });
      }
      .width('100%')
      .margin({ bottom: 12 })
      .justifyContent(FlexAlign.SpaceBetween);

      List() {
        ListItem() {
          this.importOptionBuilder(IMPORT_OPTS[0]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          this.getUIContext()
            .getPromptAction()
            .openCustomDialog({
              builder: () => {
                this.createFolderDialogBuilder();
              },
              width: '90%',
              autoCancel: false,
              alignment: DialogAlignment.Center,
              transition: TransitionEffect.SLIDE,
              onWillAppear: () => {
                this.newPlaylistName = undefined;
              }
            })
            .then((dialogId: number) => {
              this.createPlaylistDialogId = dialogId;
            })
            .catch((err: BusinessError) => {
              console.error(`Failed to open create playlist dialog. Cuase: ${JSON.stringify(err)}`);
            });
        });

        ListItem() {
          this.importOptionBuilder(IMPORT_OPTS[1]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          let context = this.getUIContext().getHostContext() as Context;
          this.audioLibVM.importAudioFromAudioLib(context);
        });

        ListItem() {
          this.importOptionBuilder(IMPORT_OPTS[2]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          let context = this.getUIContext().getHostContext() as Context;
          this.audioLibVM.importAudioFromFileMgr(context);
        });

        ListItem() {
          this.importOptionBuilder(IMPORT_OPTS[3]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          let context = this.getUIContext().getHostContext() as Context;
          this.audioLibVM.importAudioFromDownloadDir(context);
        });
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, startMargin: 46, color: $r('sys.color.comp_divider') });
    }
    .padding(16);
  }

  @Builder
  sortHeader() {
    Row() {
      Text('排序方式')
        .fontSize(14)
        .fontColor($r('sys.color.font_primary'));

      Image(this.isSortExpand ? $r('app.media.chevron_up') : $r('app.media.chevron_down'))
        .width(20)
        .aspectRatio(1)
        .backgroundColor(Color.Transparent)
        .fillColor($r('sys.color.font_primary'));
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(() => {
      this.isSortExpand = !this.isSortExpand;
    })
    .onTouch((event) => {
      event.stopPropagation();
    });
  }

  @Builder
  audioSortBuilder() {
    ListItem() {
      Row({ space: 8 }) {
        Text('标题')
          .fontSize(14)
          .fontColor($r('sys.color.font_primary'));

        if (this.audioLibVM.audioSortMode === SortModeValue.AUDIO_TITLE) {
          Image(
            this.audioLibVM.audioSortRule === SortRuleValue.ASCENDING ?
              $r('app.media.text_and_arrow_down') :
              $r('app.media.text_and_arrow_up')
          )
            .width(20)
            .aspectRatio(1)
            .backgroundColor(Color.Transparent)
            .fillColor($r('sys.color.font_primary'));
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Start);
    }
    .width('100%')
    .margin({ left: 16 })
    .padding({ bottom: 16 })
    .borderWidth({ bottom: 0.5 })
    .borderColor($r('sys.color.comp_divider'))
    .onClick(() => {
      this.audioLibVM.selectAudioSortMethod(SortModeValue.AUDIO_TITLE);
    });

    ListItem() {
      Row({ space: 8 }) {
        Text('创建时间')
          .fontSize(14)
          .fontColor($r('sys.color.font_primary'));

        if (this.audioLibVM.audioSortMode === SortModeValue.DATE_ADD) {
          Image(
            this.audioLibVM.audioSortRule === SortRuleValue.ASCENDING ?
              $r('app.media.text_and_arrow_down') :
              $r('app.media.text_and_arrow_up')
          )
            .width(20)
            .aspectRatio(1)
            .backgroundColor(Color.Transparent)
            .fillColor($r('sys.color.font_primary'));
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Start);
    }
    .width('100%')
    .margin({ left: 16 })
    .borderColor($r('sys.color.comp_divider'))
    .padding({ top: 16, bottom: 16 })
    .onClick(() => {
      this.audioLibVM.selectAudioSortMethod(SortModeValue.DATE_ADD);
    });
  }

  @Builder
  playlistSortBuilder() {
    ListItem() {
      Row({ space: 8 }) {
        Text('名称')
          .fontSize(14)
          .fontColor($r('sys.color.font_primary'));

        if (this.audioLibVM.playlistSortMode === SortModeValue.PLAYLIST_NAME) {
          Image(
            this.audioLibVM.playlistSortRule === SortRuleValue.ASCENDING ?
              $r('app.media.text_and_arrow_down') :
              $r('app.media.text_and_arrow_up')
          )
            .width(20)
            .aspectRatio(1)
            .backgroundColor(Color.Transparent)
            .fillColor($r('sys.color.font_primary'));
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Start);
    }
    .width('100%')
    .margin({ left: 16 })
    .padding({ bottom: 16 })
    .borderWidth({ bottom: 0.5 })
    .borderColor($r('sys.color.comp_divider'))
    .onClick(() => {
      this.audioLibVM.selectPlaylistSortMethod(SortModeValue.PLAYLIST_NAME);
    });

    ListItem() {
      Row({ space: 8 }) {
        Text('创建时间')
          .fontSize(14)
          .fontColor($r('sys.color.font_primary'));

        if (this.audioLibVM.playlistSortMode === SortModeValue.DATE_ADD) {
          Image(
            this.audioLibVM.playlistSortRule === SortRuleValue.ASCENDING ?
              $r('app.media.text_and_arrow_down') :
              $r('app.media.text_and_arrow_up')
          )
            .width(20)
            .aspectRatio(1)
            .backgroundColor(Color.Transparent)
            .fillColor($r('sys.color.font_primary'));
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Start);
    }
    .width('100%')
    .margin({ left: 16 })
    .padding({ top: 16, bottom: 16 })
    .borderColor($r('sys.color.comp_divider'))
    .onClick(() => {
      this.audioLibVM.selectPlaylistSortMethod(SortModeValue.DATE_ADD);
    });
  }

  @Builder
  moreOptionsBuilder() {
    List() {
      ListItem() {
        Row() {
          Text(this.audioViewOptions === ViewOptionValue.LIST_VIEW ? '宫格视图' : '列表视图')
            .fontSize(14)
            .fontColor($r('sys.color.font_primary'));
        }
        .width('100%')
        .justifyContent(FlexAlign.Start);
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(async () => {
        if (this.audioViewOptions === ViewOptionValue.LIST_VIEW) {
          await this.audioLibVM.selectViewOption(ViewOptionValue.GRID_VIEW);
          this.audioViewOptions = ViewOptionValue.GRID_VIEW;
        } else {
          await this.audioLibVM.selectViewOption(ViewOptionValue.LIST_VIEW);
          this.audioViewOptions = ViewOptionValue.LIST_VIEW;
        }
      });

      if (this.currAudioList || this.selectedIndex === 0) {
        ListItemGroup({
          header: this.sortHeader(),
          style: ListItemGroupStyle.NONE,
        }) {
          if (this.isSortExpand) {
            if (this.currAudioList) {
              this.audioSortBuilder();
            } else {
              this.playlistSortBuilder();
            }
          }
        }
        .width('100%');
      }
    }
    .width(200)
    .divider({
      strokeWidth: 0.5,
      color: $r('sys.color.comp_divider'),
    })
    .padding({ left: 8, right: 8 });
  }

  @Builder
  createFolderDialogBuilder() {
    Column() {
      Row() {
        Text('新建歌单')
          .fontSize(16)
          .fontWeight(FontWeight.Bold);
      }
      .width('100%')
      .margin({ bottom: 12 })
      .justifyContent(FlexAlign.Center);

      TextInput({ placeholder: '新建歌单' })
        .id('createFolderTextInput')
        .fontSize(14)
        .maxLength(100)
        .showUnderline(true)
        .underlineColor(Color.Gray)
        .placeholderFont({ size: 14 })
        .backgroundColor(Color.Transparent)
        .bindPopup(this.invalidName, {
          message: `文件名不能包含以下任何字符: ${INVALID_VALUES}`,
          placement: Placement.BottomRight,
        })
        .onAppear(() => {
          try {
            this.getUIContext().getFocusController().requestFocus('createFolderTextInput');
          } catch (error) {
            console.error(`Failed to request focus for createFolder TextInput. Cause: ${JSON.stringify(error)}`);
          }
        })
        .onWillInsert((value: InsertValue) => {
          if (INVALID_VALUES.includes(value.insertValue)) {
            this.invalidName = true;
            setTimeout(() => {
              this.invalidName = false;
            }, 3000);
          } else {
            this.invalidName = false;
          }
          return !this.invalidName;
        })
        .onChange((value: string) => {
          this.newPlaylistName = value;
        });

      Row() {
        Button({ type: ButtonType.Capsule, stateEffect: false }) {
          Text('取消')
            .fontSize(14)
            .fontColor('#FF007DFF');
        }
        .padding(8)
        .width('50%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.createPlaylistDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
        });

        Divider()
          .height(24)
          .vertical(true)
          .strokeWidth(1)
          .color('#DCDCDC');

        Button({ type: ButtonType.Capsule, stateEffect: false }) {
          Text('创建')
            .fontSize(14)
            .fontColor('#FF007DFF');
        }
        .padding(8)
        .width('50%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.createPlaylistDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          if (this.newPlaylistName !== undefined) {
            this.audioLibVM.createAudioPlaylist(this.newPlaylistName);
          }
        });
      }
      .width('100%')
      .margin({ top: 12 })
      .justifyContent(FlexAlign.SpaceBetween);
    }
    .padding(16);
  }

  @Builder
  ChoiceOptionBuilder(icon: ResourceStr, name: ResourceStr, color: ResourceColor, callback: Callback<void>) {
    Column({ space: 2 }) {
      Image(icon)
        .width(24)
        .aspectRatio(1)
        .fillColor(color);
      Text(name)
        .fontSize(12)
        .fontColor(color);
    }
    .height('100%')
    .padding({ top: 8 })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      callback();
    });
  }

  @Builder
  multiChoiceBuilder() {
    Row() {
      this.ChoiceOptionBuilder($r('app.media.trash'), '删除', Color.Red,
        () => {
          emitter.emit(DELETE_CHOICE_EVENT);
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.multiChoiceDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
        });

      if (
        this.currAudioList?.type === AudioListType.PLAY_LIST &&
          ![ALL_AUDIO, FAVORITE_AUDIO].includes(this.currAudioList.name ?? '')
      ) {
        this.ChoiceOptionBuilder($r('app.media.remove_songlist'), '从歌单移除', $r('sys.color.font_primary'),
          () => {
            emitter.emit(DELETE_PLAYLIST_CHOICE_EVENT);
            try {
              this.getUIContext().getPromptAction().closeCustomDialog(this.multiChoiceDialogId);
            } catch (error) {
              console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
            }
          });
      }

      this.ChoiceOptionBuilder($r('app.media.music_note_list'), '添加到歌单', $r('sys.color.font_primary'),
        () => {
          emitter.emit(ADD_PLAYLIST_CHOICE_EVENT);
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.multiChoiceDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
        });
    }
    .width('100%')
    .height('100%')
    .padding({ left: 32, right: 32 })
    .alignItems(VerticalAlign.Top)
    .justifyContent(FlexAlign.SpaceAround);
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      if (!this.multiChoice) {
        Row() {
          Row({ space: 12 }) {
            if (this.currAudioList) {
              Button({ type: ButtonType.Circle, stateEffect: false }) {
                Image($r('app.media.back'))
                  .width(14)
                  .aspectRatio(1)
                  .fillColor($r('sys.color.font_primary'));
              }
              .width(36)
              .aspectRatio(1)
              .backgroundColor($r('sys.color.background_tertiary'))
              .onClick(() => {
                this.audioTabStack.pop();
              });
            }

            Text(this.setAudioTitleText(this.currAudioList))
              .maxLines(1)
              .fontSize(20)
              .layoutWeight(1)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .layoutWeight(1);

          Row({ space: 12 }) {
            if (this.currAudioList) {
              Button({ type: ButtonType.Capsule, stateEffect: false }) {
                Text('多选')
                  .fontSize(14)
                  .fontColor($r('sys.color.font_primary'));
              }
              .width(36 * 1.5)
              .aspectRatio(1.5)
              .backgroundColor($r('sys.color.background_tertiary'))
              .onClick(() => {
                this.getUIContext()
                  .getPromptAction()
                  .openCustomDialog({
                    builder: () => {
                      this.multiChoiceBuilder();
                    },
                    width: '100%',
                    height: 56 + this.getUIContext().px2vp(this.bottomRectHeight),
                    isModal: false,
                    cornerRadius: 0,
                    alignment: DialogAlignment.Bottom,
                    transition: TransitionEffect.SLIDE,
                    offset: { dx: 0, dy: this.getUIContext().px2vp(this.bottomRectHeight) },
                    onWillAppear: () => {
                      this.multiChoice = true;
                    },
                    onWillDisappear: () => {
                      this.multiChoice = false;
                      this.choiceAll = true;
                      this.choiceCount = 0;
                    }
                  })
                  .then((dialogId: number) => {
                    this.multiChoiceDialogId = dialogId;
                  })
                  .catch((err: BusinessError) => {
                    console.error(`Failed to open import dialog. Cuase: ${JSON.stringify(err)}`);
                  });
              });
            }

            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.plus'))
                .width(24)
                .aspectRatio(1)
                .fillColor($r('sys.color.font_primary'));
            }
            .width(36)
            .aspectRatio(1)
            .backgroundColor($r('sys.color.background_tertiary'))
            .onClick(() => {
              this.getUIContext()
                .getPromptAction()
                .openCustomDialog({
                  builder: () => {
                    this.importDialogBuilder();
                  },
                  width: '100%',
                  alignment: DialogAlignment.Bottom,
                  transition: TransitionEffect.SLIDE,
                  offset: { dx: 0, dy: this.getUIContext().px2vp(this.bottomRectHeight) }
                })
                .then((dialogId: number) => {
                  this.importDialogId = dialogId;
                })
                .catch((err: BusinessError) => {
                  console.error(`Failed to open import dialog. Cuase: ${JSON.stringify(err)}`);
                });
            });

            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.dot_grid_2x2'))
                .width(24)
                .aspectRatio(1)
                .fillColor($r('sys.color.font_primary'));
            }
            .width(36)
            .aspectRatio(1)
            .backgroundColor($r('sys.color.background_tertiary'))
            .bindMenu(
              this.moreOptionsBuilder,
              {
                onDisappear: () => {
                  this.isSortExpand = false;
                }
              }
            );
          };
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({
          top: 8,
          left: 16,
          right: 16,
          bottom: 8,
        });
      } else {
        Row() {
          Row({ space: 12 }) {
            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.xmark'))
                .width(24)
                .aspectRatio(1)
                .fillColor($r('sys.color.font_primary'));
            }
            .width(36)
            .aspectRatio(1)
            .backgroundColor($r('sys.color.background_tertiary'))
            .onClick(() => {
              try {
                this.getUIContext().getPromptAction().closeCustomDialog(this.multiChoiceDialogId);
              } catch (error) {
                console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
              }
            });

            Text(this.choiceCount === 0 ? '未选择' : `已选择 ${this.choiceCount} 项`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'));
          };

          Button({ type: ButtonType.Capsule, stateEffect: false }) {
            Text(this.choiceAll ? '全选' : '取消全选')
              .fontSize(14)
              .fontColor($r('sys.color.font_primary'));
          }
          .width(36 * (this.choiceAll ? 1.5 : 2))
          .aspectRatio(this.choiceAll ? 1.5 : 2)
          .backgroundColor($r('sys.color.background_tertiary'))
          .onClick(() => {
            emitter.emit(CHOICE_ALL_EVENT);
          });
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({
          top: 8,
          left: 16,
          right: 16,
          bottom: 8,
        });
      }

      Stack({ alignContent: Alignment.Bottom }) {
        Navigation(this.audioTabStack) {
          Tabs() {
            TabContent() {
              AudioPlayListView();
            }
            .tabBar(
              SubTabBarStyle
                .of('歌单')
                .labelStyle({
                  maxLines: 1,
                  font: { size: 14 },
                  overflow: TextOverflow.Ellipsis
                })
            );

            TabContent() {
              AudioAlbumListView();
            }
            .tabBar(
              SubTabBarStyle
                .of('专辑')
                .labelStyle({
                  maxLines: 1,
                  font: { size: 14 },
                  overflow: TextOverflow.Ellipsis
                })
            );

            TabContent() {
              AudioArtistListView();
            }
            .tabBar(
              SubTabBarStyle
                .of('艺术家')
                .labelStyle({
                  maxLines: 1,
                  font: { size: 14 },
                  overflow: TextOverflow.Ellipsis
                })
            );
          }
          .onSelected((index: number) => {
            this.selectedIndex = index;
          });
        }
        .hideToolBar(true)
        .mode(NavigationMode.Stack);

        Row() {
          AudioBottomBar()
            .margin({ left: 8, right: 8, bottom: 8 });
        }
        .height(60)
        .width('100%');
      };
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.getUIContext().px2vp(this.topRectHeight) });
  }

  private setAudioTitleText(audioListInfo: AudioListInfo | undefined): string {
    if (!audioListInfo) {
      if (this.selectedIndex === 0) {
        return '歌单';
      } else if (this.selectedIndex === 1) {
        return '专辑';
      } else if (this.selectedIndex === 2) {
        return '艺术家';
      } else {
        return '音频';
      }
    }
    switch (audioListInfo.type) {
      case AudioListType.PLAY_LIST:
        if (audioListInfo.name === ALL_AUDIO) {
          return '全部音频';
        } else if (audioListInfo.name === FAVORITE_AUDIO) {
          return '我的收藏';
        }
        break;
      case AudioListType.ALNUM_LIST:
        if (!audioListInfo.name) {
          return '未知专辑';
        }
        break;
      case AudioListType.ARTIST_LIST:
        if (!audioListInfo.name) {
          return '未知艺术家';
        }
        break;
    }
    return audioListInfo.name!;
  }
}