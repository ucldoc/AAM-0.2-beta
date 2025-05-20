#!/bin/bash
# AAM v0.2 - Automatisches Anruf-Makeln
# Start mit: ./aam.sh /pfad/zur/nummernliste.txt

# --- Konfiguration ---
REC_DIR="./rec"
MAX_PARTICIPANTS=5
MAX_TIME_MINUTES=30
AUDIO_FORMAT="wav"
EXPERT_MODE=true

# --- Audioaufnahme vorbereiten ---
mkdir -p "$REC_DIR"
REC_FILE="$REC_DIR/aufnahme_$(date +'%Y-%m-%d_%H-%M-%S').$AUDIO_FORMAT"

# --- Eingaben abfragen ---
echo "📞 AAM v0.2 - Makel-Assistent"
read -p "📋 Pfad zur Nummernliste [${1:-none}]: " nummerndatei
nummerndatei=${nummerndatei:-$1}

if [ ! -f "$nummerndatei" ]; then
  echo "❌ Fehler: Nummernliste nicht gefunden!"
  exit 1
fi

read -p "👥 Max. Teilnehmer [${MAX_PARTICIPANTS}]: " max_teilnehmer
MAX_PARTICIPANTS=${max_teilnehmer:-$MAX_PARTICIPANTS}

read -p "⏱ Max. Laufzeit (Minuten) [${MAX_TIME_MINUTES}]: " max_zeit
MAX_TIME_MINUTES=${max_zeit:-$MAX_TIME_MINUTES}

# --- PJSIP starten mit Konfiguration ---
echo "🔈 Starte Aufnahme: $REC_FILE"
pjsua --local-port=5060 \
  --rec-file="$REC_FILE" \
  --max-calls="$MAX_PARTICIPANTS" \
  --duration="$MAX_TIME_MINUTES" \
  --auto-answer=200 \
  --play-file="$REC_FILE" &  # Hintergrund

# --- Nummern importieren und anrufen ---
echo "📞 Starte Makeln mit $(wc -l < "$nummerndatei") Nummern..."
while read -r nummer; do
  pjsua --call sip:"$nummer"@yourprovider.com
  sleep 5  # Wartezeit zwischen Anrufen
done < "$nummerndatei"

# --- Expertenmodus-Logging ---
if [ "$EXPERT_MODE" = true ]; then
  echo "🔍 Expertenmodus: SIP-Logs werden angezeigt..."
  tail -f pjsua.log | grep --color -E 'Call|DTMF|Error'
fi

echo "✅ Fertig! Aufnahme gespeichert unter: $REC_FILE"
