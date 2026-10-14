import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;
const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

      let windowClass: window.Window | undefined = undefined;
      try {
        windowClass = windowStage.getMainWindowSync();
      } catch (error) {
        console.error(`Failed to get main window, error: ${JSON.stringify(error)}`);
      }

      windowClass?.setWindowLayoutFullScreen(true)
        .then(() => {
          console.info(`Succeed in set main window full-screen`);

          windowClass?.on('avoidAreaChange', (avoidAreaOpts: window.AvoidAreaOptions) => {
            if (avoidAreaOpts.type === window.AvoidAreaType.TYPE_SYSTEM) {
              let topRectHeight = avoidAreaOpts.area.topRect.height;
              if (topRectHeight !== 0) {
                AppStorage.setOrCreate(TOP_RECT_HEIGHT, topRectHeight);
              }
            } else if (avoidAreaOpts.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
              let bottomRectHeight = avoidAreaOpts.area.bottomRect.height;
              if (bottomRectHeight !== 0) {
                AppStorage.setOrCreate(BOTTOM_RECT_HEIGHT, bottomRectHeight);
              }
            }
          });

          try {
            let avoidArea = windowClass?.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
            let bottomRectHeight = avoidArea?.bottomRect.height;
            AppStorage.setOrCreate(BOTTOM_RECT_HEIGHT, bottomRectHeight);
          } catch (error) {
            console.error(`Failed to get bottom avoid area, error: ${JSON.stringify(error)}`);
          }

          try {
            let avoidArea = windowClass?.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
            let topRectHeight = avoidArea?.bottomRect.height;
            AppStorage.setOrCreate(TOP_RECT_HEIGHT, topRectHeight);
          } catch (error) {
            console.error(`Failed to get top avoid area, error: ${JSON.stringify(error)}`);
          }
        })
        .catch((error: BusinessError) => {
          console.error(`Failed to set main window full-screen, error: ${JSON.stringify(error)}`);
        });
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
};