const base = "h-4 w-4";

export function FacebookIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={base} {...props}>
      <path d="M13.5 21v-7.6h2.55l.38-2.96h-2.93V8.57c0-.86.24-1.44 1.47-1.44h1.57V4.5c-.27-.04-1.2-.12-2.28-.12-2.26 0-3.8 1.38-3.8 3.9v2.17H8V13.4h2.46V21h3.04Z" />
    </svg>
  );
}

export function InstagramIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={base} {...props}>
      <rect x="3.5" y="3.5" width="17" height="17" rx="5" />
      <circle cx="12" cy="12" r="4" />
      <circle cx="17.2" cy="6.8" r="1" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function YoutubeIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={base} {...props}>
      <rect x="2.5" y="6" width="19" height="12" rx="4" />
      <path d="M10.5 9.5v5l4.5-2.5-4.5-2.5Z" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function TiktokIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={base} {...props}>
      <path d="M14.5 3h2.1c.2 1.6 1.2 2.9 2.9 3.3v2.2c-1.1 0-2.1-.3-3-.9v6.1c0 3-2.4 5.3-5.4 5.3S5.7 16.7 5.7 13.7c0-2.9 2.2-5.1 5.1-5.3v2.2c-1.6.2-2.9 1.5-2.9 3.1 0 1.7 1.4 3.1 3.1 3.1s3.1-1.4 3.1-3.1V3Z" />
    </svg>
  );
}