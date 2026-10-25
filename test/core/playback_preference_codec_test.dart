import 'package:flutter_test/flutter_test.dart';
import 'package:pure_music/core/enums.dart';
import 'package:pure_music/core/preference.dart';

void main() {
  test('codec preserves protected audio preference fields', () {
    final preference = PlaybackPreferenceCodec.decode({
      'playMode': 'PlayMode.forward',
      'volumeDsp': 0.8,
      'eqGains': List<double>.filled(10, 1.5),
      'eqEnabled': false,
      'replayGainEnabled': true,
      'replayGainMode': 'album',
      'skipLeadingSilence': true,
      'transitionMode': 'smart',
      'transitionFadeOutMs': 900,
      'transitionFadeInMs': 700,
    });

    expect(preference.eqEnabled, isFalse);
    expect(preference.replayGainEnabled, isTrue);
    expect(preference.replayGainMode, ReplayGainMode.album);
    expect(preference.skipLeadingSilence, isTrue);
    expect(preference.transitionMode, TransitionMode.smart);
    expect(preference.transitionFadeOutMs, 900);
    expect(preference.transitionFadeInMs, 700);
    expect(
      PlaybackPreferenceCodec.encode(preference)['transitionMode'],
      'smart',
    );
  });

  test('missing replayGainMode defaults to track', () {
    final preference = PlaybackPreferenceCodec.decode({
      'replayGainEnabled': true,
    });
    expect(preference.replayGainMode, ReplayGainMode.track);
    expect(
      PlaybackPreferenceCodec.encode(preference)['replayGainMode'],
      'track',
    );
  });

  test('output devices are remembered independently by playback mode', () {
    final preference = PlaybackPreferenceCodec.decode({
      'sharedOutputDevice': 'shared:realtek',
      'wasapiOutputDevice': 'wasapi:usb-dac',
    });

    expect(preference.sharedOutputDevice, 'shared:realtek');
    expect(preference.wasapiOutputDevice, 'wasapi:usb-dac');
    final encoded = PlaybackPreferenceCodec.encode(preference);
    expect(encoded['sharedOutputDevice'], 'shared:realtek');
    expect(encoded['wasapiOutputDevice'], 'wasapi:usb-dac');
  });

  test('legacy output device value migrates to both playback modes', () {
    final preference = PlaybackPreferenceCodec.decode({
      'audioOutputDevice': 'Legacy Device',
    });

    expect(preference.sharedOutputDevice, 'Legacy Device');
    expect(preference.wasapiOutputDevice, 'Legacy Device');
  });
}
