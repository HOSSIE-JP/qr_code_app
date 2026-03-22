import Flutter
import MSAL
import UIKit

class SceneDelegate: FlutterSceneDelegate {
	override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		guard let urlContext = URLContexts.first else {
			return
		}

		MSALPublicClientApplication.handleMSALResponse(
			urlContext.url,
			sourceApplication: urlContext.options.sourceApplication
		)
	}
}
