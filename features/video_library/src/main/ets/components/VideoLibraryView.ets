import { VideoLibraryViewModel } from '../viewmodel/VideoLibraryViewModel';
import { emitter } from '@kit.BasicServicesKit';
import { FolderInfoModel } from 'data_storage/src/main/ets/rdbms/FolderInfoModel';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import { SortModeValue, SortRuleValue, ViewOptionValue } from 'data_storage';

const ROOT_FOLDER = '/';
const SECRET_FOLDER = '/*/';
const INVALID_VALUES = '/\\:*?"<>|';
const CHOICE_ALL = 'ChoiceAll';
const CHOICE_COUNT = 'ChoiceCount';
const CHOICE_ALL_EVENT = 'ChoiceAll';
const MOVE_SECRET_EVENT = 'MoveSecret';
const MOVE_CHOICE_EVENT = 'MoveChoice';
const SHARE_CHOICE_EVENT = 'ShareChoice';
const DELETE_CHOICE_EVENT = 'DeleteChoice';
const MULTI_CHOICE = 'MultiChoice';
const CURRENT_FOLDER = 'CurrentFolder';
const VIDEO_TAB_STACK = 'VideoTabStack';
const VIDEO_VIEW_OPTION = 'VideoViewOption';
const IN_SECRET_FOLDER = 'InSecretFolder';
const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';
const IMPORT_OPTS: ImportOption[] = [
  { icon: $r('app.media.folder_badge_plus'), text: '创建文件夹', color: Color.Green },
  { icon: $r('app.media.picture_2'), text: '系统图库导入', color: Color.Blue },
  { icon: $r('app.media.folder'), text: '文件管理导入', color: Color.Orange },
  { icon: $r('app.media.download_folder'), text: '下载目录导入', color: Color.Red },
];

interface ImportOption {
  color: ResourceColor,
  icon: Resource,
  text: string
};

@Component
export struct VideoLibraryView {
  @Provide(CHOICE_ALL) choiceAll: boolean = true;
  @Provide(CHOICE_COUNT) choiceCount: number = 0;
  @Provide(MULTI_CHOICE) multiChoice: boolean = false;
  @Provide(CURRENT_FOLDER) currFolder: string = ROOT_FOLDER;
  @Provide(IN_SECRET_FOLDER) inSecretFolder: boolean = false;
  @Provide(VIDEO_VIEW_OPTION) videoViewOptions: ViewOptionValue = ViewOptionValue.LIST_VIEW;
  @Provide(VIDEO_TAB_STACK) videoTabStack: NavPathStack = new NavPathStack();
  @State videoLibVM: VideoLibraryViewModel = new VideoLibraryViewModel(this.getUIContext().getHostContext() as Context);
  @State invalidName: boolean = false;
  @State isSortExpand: boolean = false;
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  private newFolderName?: string;
  private importDialogId: number = 0;
  private multiChoiceDialogId: number = 0;
  private createFolderDialogId: number = 0;

  async aboutToAppear(): Promise<void> {
    await this.videoLibVM.init();
    this.videoViewOptions = await this.videoLibVM.getViewOptions();
  }

  private async getRandom(len: number): Promise<Uint8Array | undefined> {
    try {
      let rand = cryptoFramework.createRandom();
      let result = await rand.generateRandom(len);
      return result.data;
    } catch (error) {
      console.error(`Failed to generate random. Cause: ${JSON.stringify(error)}`);
      return undefined;
    }
  }

  private currFolderName(folder: string): string {
    if (folder === ROOT_FOLDER) {
      return '视频';
    } else if (folder === SECRET_FOLDER) {
      return '保险柜';
    } else {
      let prevSlashIdx = folder.lastIndexOf('/', folder.length - 2);
      let folderName = folder.slice(prevSlashIdx + 1, folder.length - 1);
      return folderName;
    }
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
  moreOptionsBuilder() {
    List() {
      ListItem() {
        Row() {
          Text(this.videoViewOptions === ViewOptionValue.LIST_VIEW ? '宫格视图' : '列表视图')
            .fontSize(14)
            .fontColor($r('sys.color.font_primary'));
        }
        .width('100%')
        .justifyContent(FlexAlign.Start);
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(async () => {
        if (this.videoViewOptions === ViewOptionValue.LIST_VIEW) {
          await this.videoLibVM.selectViewOption(ViewOptionValue.GRID_VIEW);
          this.videoViewOptions = ViewOptionValue.GRID_VIEW;
        } else {
          await this.videoLibVM.selectViewOption(ViewOptionValue.LIST_VIEW);
          this.videoViewOptions = ViewOptionValue.LIST_VIEW;
        }
      });

      ListItemGroup({
        header: this.sortHeader(),
        style: ListItemGroupStyle.NONE,
      }) {
        if (this.isSortExpand) {
          ListItem() {
            Row({ space: 8 }) {
              Text('创建时间')
                .fontSize(14)
                .fontColor($r('sys.color.font_primary'));

              if (this.videoLibVM.sortMode === SortModeValue.DATE_ADD) {
                Image(
                  this.videoLibVM.sortRule === SortRuleValue.ASCENDING ?
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
          .borderWidth({ bottom: 0.5 })
          .borderColor($r('sys.color.comp_divider'))
          .padding({ bottom: 16 })
          .onClick(() => {
            this.videoLibVM.selectSortMethod(SortModeValue.DATE_ADD);
          });

          ListItem() {
            Row({ space: 8 }) {
              Text('文件名称')
                .fontSize(14)
                .fontColor($r('sys.color.font_primary'));

              if (this.videoLibVM.sortMode === SortModeValue.FILE_NAME) {
                Image(
                  this.videoLibVM.sortRule === SortRuleValue.ASCENDING ?
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
          .borderWidth({ bottom: 0.5 })
          .borderColor($r('sys.color.comp_divider'))
          .padding({ top: 16, bottom: 16 })
          .onClick(() => {
            this.videoLibVM.selectSortMethod(SortModeValue.FILE_NAME);
          });

          ListItem() {
            Row({ space: 8 }) {
              Text('文件大小')
                .fontSize(14)
                .fontColor($r('sys.color.font_primary'));

              if (this.videoLibVM.sortMode === SortModeValue.FILE_SIZE) {
                Image(
                  this.videoLibVM.sortRule === SortRuleValue.ASCENDING ?
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
          .onClick(() => {
            this.videoLibVM.selectSortMethod(SortModeValue.FILE_SIZE);
          });
        }
      }
      .width('100%');

      ListItem() {
        Row() {
          Text('保险柜')
            .fontSize(14)
            .fontColor($r('sys.color.font_primary'));
        }
        .width('100%')
        .justifyContent(FlexAlign.Start);
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(async () => {
        try {
          const randData = await this.getRandom(32);
          if (!randData) {
            return;
          }
          // 设置认证参数
          const authParam: userAuth.AuthParam = {
            challenge: randData,
            authTrustLevel: userAuth.AuthTrustLevel.ATL3,
            authType: [userAuth.UserAuthType.FINGERPRINT, userAuth.UserAuthType.PIN],
          };
          // 配置认证界面
          const widgetParam: userAuth.WidgetParam = {
            title: '用于解锁保险柜'
          };
          // 获取认证对象
          const userAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
          // 订阅认证结果
          userAuthInstance.on('result', {
            onResult: (result: userAuth.UserAuthResult) => {
              if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
                let folderInfo = new FolderInfoModel();
                folderInfo.path = SECRET_FOLDER;
                folderInfo.parent = ROOT_FOLDER;
                this.videoTabStack.pushPath({ name: 'VideoBrowser', param: folderInfo });
              }
              userAuthInstance.off('result');
            }
          });
          userAuthInstance.start();
        } catch (error) {
          console.error(`Initial UserAuth failed. Cause: ${JSON.stringify(error)}`);
        }
      });
    }
    .width(200)
    .padding({ left: 8, right: 8 })
    .divider({
      strokeWidth: 0.5,
      color: $r('sys.color.comp_divider')
    });
  }

  @Builder
  createFolderDialogBuilder() {
    Column() {
      Row() {
        Text('新建文件夹')
          .fontSize(16)
          .fontWeight(FontWeight.Bold);
      }
      .width('100%')
      .margin({ bottom: 12 })
      .justifyContent(FlexAlign.Center);

      TextInput({ placeholder: '新建文件夹' })
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
          this.newFolderName = value;
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
            this.getUIContext().getPromptAction().closeCustomDialog(this.createFolderDialogId);
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
            this.getUIContext().getPromptAction().closeCustomDialog(this.createFolderDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          if (this.newFolderName !== undefined) {
            let newFolder = this.currFolder + this.newFolderName + '/';
            this.videoLibVM.createVideoFolder(newFolder, this.currFolder);
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
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'));

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
                this.newFolderName = undefined;
              }
            })
            .then((dialogId: number) => {
              this.createFolderDialogId = dialogId;
            })
            .catch((err: BusinessError) => {
              console.error(`Failed to open create folder dialog. Cuase: ${JSON.stringify(err)}`);
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
          this.videoLibVM.importVideoFromMediaLib(this.currFolder);
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
          this.videoLibVM.importVideoFromFileMgr(this.currFolder);
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
          this.videoLibVM.importVideoFromDownloadDir(this.currFolder);
        });
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, startMargin: 46, color: $r('sys.color.comp_divider') });
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

      this.ChoiceOptionBuilder($r('app.media.arrow_right_folder_circle'), '移动', $r('sys.color.font_primary'),
        () => {
          emitter.emit(MOVE_CHOICE_EVENT);
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.multiChoiceDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
        });

      if (this.inSecretFolder) {
        this.ChoiceOptionBuilder($r('app.media.lock_open'), '移出', $r('sys.color.font_primary'),
          () => {
            emitter.emit(MOVE_SECRET_EVENT);
            try {
              this.getUIContext().getPromptAction().closeCustomDialog(this.multiChoiceDialogId);
            } catch (error) {
              console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
            }
          });
      } else {
        this.ChoiceOptionBuilder($r('app.media.lock'), '保险柜', $r('sys.color.font_primary'),
          () => {
            emitter.emit(MOVE_SECRET_EVENT);
            try {
              this.getUIContext().getPromptAction().closeCustomDialog(this.multiChoiceDialogId);
            } catch (error) {
              console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
            }
          });
      }

      this.ChoiceOptionBuilder($r('app.media.share'), '分享', $r('sys.color.font_primary'),
        () => {
          emitter.emit(SHARE_CHOICE_EVENT);
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
    .justifyContent(FlexAlign.SpaceBetween);
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
            if (this.currFolder !== ROOT_FOLDER) {
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
                this.videoTabStack.pop();
              });
            }

            Text(this.currFolderName(this.currFolder))
              .maxLines(1)
              .fontSize(20)
              .layoutWeight(1)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .layoutWeight(1);

          Row({ space: 12 }) {
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

            if (!this.inSecretFolder) {
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
            }
          }
          .layoutWeight(0);
        }
        .padding(16)
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween);
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
            let eventData: emitter.EventData = {
              data: {
                'choiceAll': this.choiceAll,
              }
            };
            this.choiceAll = !this.choiceAll;
            emitter.emit(CHOICE_ALL_EVENT, eventData);
          });
        }
        .padding(16)
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween);
      }

      Navigation(this.videoTabStack, { name: 'VideoBrowser' })
        .hideToolBar(true)
        .mode(NavigationMode.Stack);
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.getUIContext().px2vp(this.topRectHeight) });
  }
}

