import 'package:vegan_motivation_app/features/paywall/paywall_data.dart';
import 'package:vegan_motivation_app/features/paywall/paywall_presenter.dart';

/// In-memory [PaywallPresenter] for tests — no RevenueCat, no native UI.
/// Records every variant presented (in order) and returns a configurable
/// [PaywallPresentResult].
///
/// Inject it with
/// `paywallPresenterProvider.overrideWithValue(FakePaywallPresenter())`.
class FakePaywallPresenter implements PaywallPresenter {
  FakePaywallPresenter({this.result = PaywallPresentResult.cancelled});

  /// What [present] returns each call. Set per test.
  PaywallPresentResult result;

  /// Every variant presented, in call order.
  final List<PaywallVariant> presented = [];

  @override
  Future<PaywallPresentResult> present(PaywallVariant variant) async {
    presented.add(variant);
    return result;
  }
}
