import { LyricsInfo } from '../model/LyricsInfoModel';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { LengthMetrics } from '@kit.ArkUI';

const AUDIO_PLAYER_VM = 'AudioPlayerVM';

@Component
export struct AudioLyricsView {
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();

  build() {
    Column() {
      if (this.audioPlayerVM.lyricsInfoArr.length === 0) {
        Column() {
          Text('暂无歌词')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'));
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else {
        Column({ space: 5 }) {
          Text(this.audioPlayerVM.currAudioItem?.title)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'));
          Text(this.audioPlayerVM.currAudioItem?.artist)
            .fontSize(14)
            .fontColor($r('sys.color.font_primary'));
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center);

        List({ space: 16, scroller: this.audioPlayerVM.lyricsScroller }) {
          ForEach(
            this.audioPlayerVM.lyricsInfoArr,
            (lyrics: LyricsInfo, index: number) => {
              ListItem() {
                Row() {
                  Text(lyrics.text)
                    .textAlign(TextAlign.Center)
                    .fontSize(this.audioPlayerVM.currLyricsIdx === index ? 18 : 14)
                    .fontColor(
                      this.audioPlayerVM.currLyricsIdx === index ?
                        $r('sys.color.font_primary') :
                        $r('sys.color.font_tertiary')
                    );
                }
                .width('100%')
                .justifyContent(FlexAlign.Center);
              };
            }
          );

          ListItem()
            .width('100%')
            .height('50%')
            .backgroundColor(Color.Transparent);
        }
        .layoutWeight(1)
        .contentStartOffset(24)
        .scrollBar(BarState.Off)
        .fadingEdge(true, { fadingEdgeLength: LengthMetrics.vp(48) })
        .onAppear(() => {
          const currLyricsIdx = this.audioPlayerVM.currLyricsIdx;
          this.audioPlayerVM.lyricsScroller.scrollToIndex(currLyricsIdx, true, ScrollAlign.CENTER);
        });
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 32, right: 32 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}