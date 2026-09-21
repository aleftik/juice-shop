describe('/', () => {
  describe('challenge "jwtUnsignedChallenge"', () => {
    it('should accept an unsigned token with email jwtn3d@juice-sh.op in the payload ', () => {
      cy.window().then(() => {
        localStorage.setItem(
          'token',
          'eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJkYXRhIjp7ImVtYWlsIjoiand0bjNkQGp1aWNlLXNoLm9wIn0sImlhdCI6MTUwODYzOTYxMiwiZXhwIjo5OTk5OTk5OTk5fQ.'
        )
      })
      cy.visit('/')
      cy.expectChallengeSolved({ challenge: 'Unsigned JWT' })
    })
  })

  describe('challenge "jwtForgedChallenge"', () => {
    it('should accept a token HMAC-signed with public RSA key with email rsa_lord@juice-sh.op in the payload ', () => {
      cy.task('isWindows').then((isWindows) => {
        if (!isWindows) {
          cy.window().then(() => {
            localStorage.setItem(
              'token',
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImVtYWlsIjoicnNhX2xvcmRAanVpY2Utc2gub3AifSwiaWF0IjoxNzkwMDA4NjI0fQ.ilDhThWudJ2UzF34JY8rRP6LL6JHqHv0Sq6jreAr3DY'
            )
          })
          cy.visit('/#/')

          cy.expectChallengeSolved({ challenge: 'Forged Signed JWT' })
        }
      })
    })
  })

  describe('challenge "iacLeakedKeyChallenge"', () => {
    it('should accept an RS256-signed token with email cloud-admin@juice-sh.op using the leaked private key', () => {
      cy.window().then(() => {
        localStorage.setItem(
          'token',
          'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImVtYWlsIjoiY2xvdWQtYWRtaW5AanVpY2Utc2gub3AifSwiaWF0IjoxNzkwMDA4NjI0fQ.WYd0rZvlFl8ahuBaNskoLS8Oxo2xFHJrD1t70HwQ7eHGxlMpmadaMAXfqQ2EEOnF0imam6xB4F53gO7H9zFPKBgosms8qez5VR0zvQybCybWGf9lxk-HofMoP4f3hqAQXj9QP3KWbRch5WgKlR4NzOBfi-K5TdNZHlnGpBosIwT4C-OydkJ1Amxm-sm_roOjcC-nmP7tbGXSDdbosOj8qVNiSNzcfIJQprWfEq-Tibj8FoUt4GFGVvg3iqWWC8z662wReVkwdK_RJIlQfYZaFOQN48E9OONFWksl2B_01WlX_oT2l-8eCXpSpLtnEm1UMCmMqQm47c_iB9SHp-OBOQ'
        )
      })
      cy.visit('/#/')
      cy.expectChallengeSolved({ challenge: 'Login Cloud Admin' })
    })
  })
})
