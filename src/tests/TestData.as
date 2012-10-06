package tests {
	
	
	/**
	 * ...
	 * @author ktu
	 */
	public class TestData {
		
        
        static public var data:Array = [
            {
                title: "F - Q - A",
                description: "\"remember\" checkbox is NOT selected.\n\nuse the quick access dialog\n\nuser clicks allow\n\nmediaPermissions should return 'granted'",
                instructions: "click start\n\nselect allow",
                expectation: "granted",
                mode: "quickAccess"
            }, {
                title: "F - Q - D",
                description: "\"remember\" checkbox is NOT selected.\n\nuse the quick access dialog\n\nuser clicks deny\n\nmediaPermissions should return 'denied'",
                instructions: "click start\n\nselect deny",
                expectation: "denied",
                mode: "quickAccess"
            }, {
                title: "F - P - A",
                description: "\"remember\" checkbox is NOT selected.\n\nuse the privacy dialog\n\nuser clicks allow\n\nmediaPermissions should return 'granted'",
                instructions: "click start\n\nselect deny\n\nclick close",
                expectation: "denied",
                mode: "privacyDialog"
            }, {
                title: "F - P - D",
                description: "\"remember\" checkbox is NOT selected.\n\nuse the privacy dialog\n\nuser clicks deny\n\nmediaPermissions should return 'denied'",
                instructions: "click start\n\nselect deny\n\n click close",
                expectation: "denied",
                mode: "privacyDialog"
            }, {
                title: "F - P - C",
                description: "\"remember\" checkbox is NOT selected.\n\nuse the privacy dialog\n\nuser clicks close\n\nmediaPermissions should return 'denied'",
                instructions: "click start\n\nselect deny\n\n click close",
                expectation: "denied",
                mode: "privacyDialog"
            }, {
                title: "T(A) - Q - N/A",
                description: "\"remember\" checkbox IS selected with allow.\n\nuse the quick access dialog\n\nuser does nothing\n\nmediaPermissions should return 'granted'",
                instructions: "click start\n\ndo nothing",
                expectation: "granted",
                mode: "quickAccess"
            }, {
                title: "T(A) - P - A",
                description: "\"remember\" checkbox IS selected with allow.\n\nuse the privacy dialog\n\nuser clicks allow\n\nmediaPermissions should return 'granted'",
                instructions: "click start\n\nselect allow (even though already selected)",
                expectation: "granted",
                mode: "privacyDialog"
            }, {
                title: "T(A) - P - D",
                description: "\"remember\" checkbox IS selected with allow.\n\nuse the privacy dialog\n\nuser clicks allow\n\nmediaPermissions should return 'denied'",
                instructions: "click start\n\nclick deny",
                expectation: "denied",
                mode: "privacyDialog"
            }, {
                title: "T(A) - P - C",
                description: "\"remember\" checkbox IS selected with allow.\n\nuse the privacy dialog\n\nuser clicks close\n\nmediaPermissions should return 'granted'",
                instructions: "click start\n\nclick close",
                expectation: "granted",
                mode: "privacyDialog"
            }, {
                title: "T(D) - Q - N/A",
                description: "\"remember\" checkbox IS selected with deny.\n\nuse the quick access dialog\n\nuser does nothing\n\nmediaPermissions should return 'denied'",
                instructions: "click start\n\ndo nothing",
                expectation: "granted",
                mode: "quickAccess"
            }, {
                title: "T(D) - P - A",
                description: "\"remember\" checkbox IS selected with deny.\n\nuse the privacy dialog\n\nuser clicks allow\n\nmediaPermissions should return 'granted'",
                instructions: "click start\n\nselect allow (even though already selected)",
                expectation: "granted",
                mode: "privacyDialog"
            }, {
                title: "T(D) - P - D",
                description: "\"remember\" checkbox IS selected with deny.\n\nuse the privacy dialog\n\nuser clicks allow\n\nmediaPermissions should return 'denied'",
                instructions: "click start\n\nclick deny",
                expectation: "denied",
                mode: "privacyDialog"
            }, {
                title: "T(D) - P - C",
                description: "\"remember\" checkbox IS selected with deny.\n\nuse the privacy dialog\n\nuser clicks close\n\nmediaPermissions should return 'denied'",
                instructions: "click start\n\nclick close",
                expectation: "denied",
                mode: "privacyDialog"
            }
        ]
        
	}

}