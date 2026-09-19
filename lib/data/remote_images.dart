/// GitHub-hosted images for Khetha Go.
///
/// To change any image, push a replacement to the `khetha-images` repo on
/// GitHub. The app loads images from the raw URL, so changes appear on next
/// app launch without an app update.
///
/// Repository structure:
///   khetha-images/
///     hero_banner.jpg    — "Explore Your Future" banner on the Home tab
///     welcome.jpg        — welcome/first-load screen background
///     coat_of_arms.png   — SA coat of arms in the header
///     khetha_logo.png    — Khetha programme logo in the header
class RemoteImages {
  RemoteImages._();

  static const repoBase =
      'https://raw.githubusercontent.com/kingmidus/khetha-images/main';

  static const heroBanner = '$repoBase/hero_banner.jpg';
  static const welcome = '$repoBase/welcome.jpg';
  static const coatOfArms = '$repoBase/coat_of_arms.png';
  static const khethaLogo = '$repoBase/khetha_logo.png';
}
