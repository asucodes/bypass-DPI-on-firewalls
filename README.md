# bypass-DPI-on-firewalls


My objective was to create a VPN service for myself which could bypass Deep Packet Inspection which restricts all UDP connections and has unnecassary web filtering. The primary goal was not just to get access, but to achieve an "FPS-feel" connection with minimal to zero network jitter, specifically for FPS games.

Most advanced firewalls block L2TP/IPsec protocols and VPN tech based on these. Since most modern VPNs and Proxifiers depend on IPsec for minimum latency, these protocols and their servers (all popular ones) are also blocked by the firewall.

However Stealth Protocols disguised as HTTPS (VLESS+WS+TLS) can help bypass these restrictions as HTTPS is the backbone of internet and firewalls cant just block these. Though DPI means they still dig deep and read the SNI (Server Name Indication) Filtering which means the server knows what website you're trying to reach eg www.chess.com. If the SNI is on a blocklist, the DPI drops the connection.

TLS Fingerprinting (The Real Problem): This is the advanced attack. The DPI doesn't just look at the SNI. It analyzes the entire structure of the Client Hello packet: The list of supported cipher suites. The order of those cipher suites. The list of TLS extensions (like GREASE) The supported elliptic curves

To bypass these comes premade tools like Xray (which powers x-ui) and sing-box, these just don't create a TLS connection, they mimic a browser like envoirnment. You are absolutely right. We've been so focused on which protocol works (IKEv2 vs. VLESS) that we haven't properly discussed why a protocol like VLESS is so effective at a deep, technical level.

My apologies. This is the most advanced and important part of the entire "cat-and-mouse game" of firewall bypassing. You've asked about the Client Hello and handshakes, which is the exact battleground where DPI operates.

Here is how it happens: 

DPI catches a "Stealth" VPN when you connect to any HTTPS site, your computer sends a ClientHello packet. This packet is the very first message in the TLS handshake, and crucially, it is NOT encrypted.

A DPI firewall like Sophos intercepts this packet and inspects it. It performs two main checks:

SNI Filtering: The ClientHello contains a field called SNI, which tells the server what website you're trying to reach (e.g. www.google.com). If the SNI is on a blocklist, the DPI drops the connection.

VLESS+WS+TLS already defeats this by our own domain (link redacted). The firewall sees this, doesn't recognize it as a "bad" domain, and lets it pass the first check.

TLS Fingerprinting is the advanced attack. The DPI doesn't just look at the SNI. It analyzes the entire structure of the ClientHello packet:

List of supported cipher suites.The order of those cipher suites, list of TLS extensions (like GREASE), supported elliptic curves,etc.

All these details create a unique "fingerprint." A real Google Chrome browser on Windows has one fingerprint. Firefox on Linux has another. A standard Go program (which Xray is written in) has its own, very different fingerprint.

Firewalls have a blocklist of these fingerprints. If your VLESS client sends a packet with the "default Go program" fingerprint, the DPI says, "Aha! That's not a browser, that's a proxy tool," and it begins to throttle or block your connection. This is almost certainly the source of the jitter you experienced.

The Bypass: How Xray and sing-box Fight Back This is where the magic of Xray (which powers x-ui) and sing-box comes in. They don't just "create a TLS connection"; they impersonate a real browser.

The key technology is called uTLS.

uTLS (or "microTLS") is a special library that gives proxy clients the power to perfectly mimic the Client Hello fingerprint of popular, real-world applications.

When you configure your client (like v2rayN or Clash), you can often specify a "fingerprint":

"fingerprint": "chrome"
"fingerprint": "firefox"

You can read more about working of uTLS on https://github.com/refraction-networking/utls

Next comes sing-box, the real MVP in our bypass DPI project:

The Problem with VLESS+TLS: If an active probe connects to your server at vpn.ieeestudent.dev, your server will present the TLS certificate for vpn.ieeestudent.dev. The firewall can see this and say, "This is a self-signed or a new Let's Encrypt certificate for an unknown domain. This is suspicious."

How sing-box with REALITY Wins:

You don't even use your own domain. You configure REALITY to impersonate a major, trusted website (e.g., www.microsoft.com). Your client sends a uTLS Client Hello, but it puts www.microsoft.com in the SNI field. The firewall sees this and thinks, "This is a Google Chrome browser connecting to Microsoft. This is high-priority, legitimate traffic." Your REALITY server receives this packet. It then actually forwards the handshake to the real www.microsoft.com server, gets back Microsoft's real TLS certificate, and passes it back to your client. A fully valid, authentic TLS connection is established with Microsoft. Your proxy traffic is then secretly embedded inside this legitimate-looking TLS session using a secret key.

Read more about sing-box [ recommended ]: https://github.com/SagerNet/sing-box

Now that we've understood how DPI works and methods used to bypass it, there is an installation guide in the same repo and another guide on network efficiency and latency issues, workarounds and result.
