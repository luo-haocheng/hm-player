import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { AudioLyricsView } from './AudioLyricsView';
import { AudioOptionsDialog } from './AudioOptionsDialog';
import { AudioPlayerView } from './AudioPlayerView';

const MAIN_PAGE_STACK = 'MainPageStack';
const AUDIO_PLAYER_VM = 'AudioPlayerVM';
const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Builder
export function AudioImmersiveBuilder() {
  AudioImmersiveView();
}

@Component
export struct AudioImmersiveView {
  @State selectedIdx: number = 0;
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @Consume(MAIN_PAGE_STACK) mainPageStack: NavPathStack = new NavPathStack();
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();
  private audioOptionsDialogCtrl?: CustomDialogController;

  @Builder
  playerTabBarBuilder() {
    Row() {
      if (this.selectedIdx === 0) {
        Row()
          .width(10)
          .height(5)
          .borderRadius('50%')
          .backgroundColor($r('sys.color.font_tertiary'));
      } else {
        Circle({ width: 5, height: 5 })
          .fill($r('sys.color.font_tertiary'))
          .fillOpacity(0.5);
      }
    }
    .width('100%')
    .height('100%')
    .padding({ right: 3 })
    .justifyContent(FlexAlign.End)
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  lyricsTabBarBuilder() {
    Row() {
      if (this.selectedIdx === 1) {
        Row()
          .width(10)
          .height(5)
          .borderRadius('50%')
          .backgroundColor($r('sys.color.font_tertiary'));
      } else {
        Circle({ width: 5, height: 5 })
          .fill($r('sys.color.font_tertiary'))
          .fillOpacity(0.5);
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 3 })
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center);
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Tabs({ barPosition: BarPosition.Start }) {
          TabContent() {
            AudioPlayerView();
          }
          .tabBar(this.playerTabBarBuilder());

          TabContent() {
            AudioLyricsView();
          }
          .tabBar(this.lyricsTabBarBuilder());
        }
        .barHeight(32)
        .onSelected((index: number) => {
          this.selectedIdx = index;
        });

        Row() {
          Button({ type: ButtonType.Circle, stateEffect: false }) {
            Image($r('app.media.chevron_down'))
              .width(28)
              .aspectRatio(1)
              .fillColor($r('sys.color.font_tertiary'));
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.mainPageStack.pop();
          });

          Button({ type: ButtonType.Circle, stateEffect: false }) {
            Image($r('app.media.dot_grid_1x2'))
              .width(28)
              .aspectRatio(1)
              .fillColor($r('sys.color.font_tertiary'));
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            if (this.audioPlayerVM.currAudioItem) {
              this.audioOptionsDialogCtrl = new CustomDialogController({
                width: '100%',
                height: '60%',
                alignment: DialogAlignment.Bottom,
                cornerRadius: { topLeft: 24, topRight: 24 },
                offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) },
                builder: AudioOptionsDialog(),
              });
              this.audioOptionsDialogCtrl.open();
            }
          });
        }
        .height(32)
        .width('100%')
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween);
      };
    }
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight),
      bottom: this.getUIContext().px2vp(this.bottomRectHeight)
    })
    .hideBackButton(true)
    .backgroundColor($r('sys.color.background_primary'));
  }
}