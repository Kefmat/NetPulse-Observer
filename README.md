# NetPulse Observer

## Enterprise Network Performance Suite

### Konsept: Fra tilgjengelighet til kvalitetssikring

I moderne IT-drift er det ikke lenger tilstrekkelig at et endepunkt svarer
på ping. NetPulse Observer er utviklet for å adressere det kritiske gapet
mellom oppetid og ytelse. Verktøyet flytter fokus fra binær overvåking
(opp/ned) til kvalitativ analyse av nettverksforbindelser.

Målet med prosjektet er å identifisere periodiske nettverksproblemer, som
jitter og pakketap, som ofte er underliggende årsaker til trege
ERP-systemer, korrupte databaser og dårlig brukeropplevelse i
PLM-miljøer.

## Arkitektur og systemdesign

NetPulse Observer er bygget på en modulær arkitektur som følger prinsippet
Separation of Concerns (SoC). Systemet er delt inn i fire distinkte lag:

1. **Detektoren (Pulse Engine)**
   Kjernen i systemet benytter .NET-klassen
   `System.Net.NetworkInformation.Ping` i stedet for standard
   PowerShell-kommandoer. Dette gir millisekundpresisjon og dypere
   kontroll over ICMP-pakker. Motoren beregner ikke bare gjennomsnittlig
   latens, men også jitter (variasjon i responstid), som er en sentral
   indikator på et ustabilt nettverk.

2. **Applikasjonskontroll (Port Validation)**
   I tillegg til ICMP-testing utfører suiten TCP-handshake-verifisering på
   definerte porter (for eksempel SQL `1433` eller SMB `445`). Dette
   sikrer at brannmurregler er korrekte, og at applikasjonslagene faktisk
   er mottakelige for trafikk.

3. **Datalagring (Time-Series Logging)**
   Alle data lagres i et strukturert CSV-format som fungerer som en enkel
   tidsseriedatabase. Systemet inkluderer en selvrensende logikk som
   automatisk roterer og sletter historikk eldre enn antall dager definert
   i konfigurasjonen.

4. **Visualiseringslag (Modern Dashboard)**
   Rapportgeneratoren transformerer rådata til et moderne HTML-grensesnitt.
   Ved bruk av dynamisk CSS-styling (fargekoding basert på terskelverdier)
   kan driftsingeniører identifisere problemområder på sekunder, uten å
   tolke tekstlogger manuelt.

## Logisk flyt

```text
[ Konfigurasjon (JSON) ] -> Definerer endepunkter, porter og terskler
              |
              v
[ Måling (.NET Engine) ] -> Utfører ping-sekvenser og portprober
              |
              v
[ Analyse og varsling ] -> Beregner jitter og utløser varsel ved avvik
              |
              v
[ Lagring og rotasjon ] -> CSV-logging med automatisk opprydding
              |
              v
[ Visualisering ] -> Generering av dashboard for beslutningsstøtte
```

## Tekniske spesifikasjoner

- **Motor:** PowerShell `5.1+` med integrert .NET Framework (`NetworkInformation`)
- **Konfigurasjon:** JSON-basert for enkel integrasjon med CI/CD-pipelines
- **Automatisering:** Støtte for Windows Task Scheduler for kontinuerlig
  monitorering (5-minutters sykluser)
- **Metrikker:** Avg Latency (ms), Jitter (ms), Packet Loss (%), Port Status (Open/Closed)

## Bruk i drift

1. **Installasjon:** Kjør `Install-NetPulse.ps1` som administrator for å
   etablere automatiske måleintervaller.
2. **Konfigurasjon:** Oppdater `config/Targets.json` med kritiske
   servere, databaser og eksterne API-er.
3. **Analyse:** Bruk `logs/PulseDashboard.html` for å identifisere om
   nettverksytelsen degraderes på bestemte tider av døgnet (for eksempel
   ved backup-kjøring eller høy trafikkbelastning).
