import './MobileAppPromo.css'

interface MobileAppPromoProps {
  version?: string
  sizeMb?: string
}

/**
 * Cross-promotion banner for the Flutter (Android) port of the app.
 * Serves the release APK bundled under `public/downloads/` so the
 * download works on any deployment target, with no external hosting.
 */
function MobileAppPromo({ version = '1.0.0', sizeMb = '48.8' }: MobileAppPromoProps) {
  return (
    <section
      className='MobileAppPromo'
      aria-label='Mobile app download'
    >
      <div className='mobile-app-promo-copy'>
        <span
          className='mobile-app-promo-icon'
          aria-hidden='true'
        >
          📱
        </span>
        <div>
          <h3>NBA Fantasy Stats — now on Android</h3>
          <p>
            Prefer tracking games from your phone? Get the native app with the
            same tracker, season progression, records and leaderboards — no
            account setup required.
          </p>
        </div>
      </div>
      <div className='mobile-app-promo-actions'>
        <a
          className='mobile-app-download-btn'
          href='downloads/nba-fantasy-stats.apk'
          download
          aria-label='Download the Android app installer (APK)'
        >
          ⬇ Download APK
        </a>
        <span className='mobile-app-promo-meta'>
          v{version} · {sizeMb} MB · Android 6.0+
        </span>
      </div>
    </section>
  )
}

export default MobileAppPromo
