# 🛡️ SIEM Lab — Wazuh Integration (Windows & Ubuntu Agents)

> Projet de laboratoire SIEM déployant **Wazuh** (Manager, Indexer, Dashboard) avec des agents **Windows Server** et **Ubuntu Server**, couplé à **Suricata IDS/IPS** et **Sysmon**, pour la détection de menaces courantes (brute force, Shellshock, processus non autorisés, commandes malveillantes) et la réponse active automatisée.

---

## 📌 Objectif du projet

Mettre en place un environnement SIEM complet permettant de :

- Centraliser les logs de plusieurs sources (Windows, Linux, IDS/IPS) dans Wazuh ;
- Détecter des attaques réelles simulées (brute force SSH/RDP, Shellshock, exécution de commandes malveillantes, processus non autorisés) ;
- Déclencher des réponses automatiques (**Active Response**) pour bloquer un attaquant ;
- Enrichir la détection avec **Sysmon** (télémétrie Windows avancée), **Snort/Suricata** (IDS/IPS réseau) et **VirusTotal** (réputation de fichiers/IOCs) ;
- Créer des règles de détection personnalisées et des tableaux de bord adaptés au contexte du lab ;
- Gérer les accès avec un utilisateur **dashboard en lecture seule**.

## 🏗️ Architecture

![Architecture](architecture/Architecture.png)

L'architecture repose sur :

- **Wazuh Manager** : collecte, analyse et corrèle les événements ;
- **Wazuh Indexer** : stockage et indexation des données (OpenSearch) ;
- **Wazuh Dashboard** : visualisation, recherche, tableaux de bord ;
- **Windows Agent** : agent Wazuh installé sur un Windows Server, couplé à Sysmon ;
- **Ubuntu Agent (1)** : agent Wazuh sur un serveur Ubuntu classique ;
- **Ubuntu Agent (2) + Suricata IDS/IPS** : serveur Ubuntu exposé faisant office de sonde réseau, transmettant les alertes Suricata à Wazuh ;
- **Attaquant** : machine externe simulant des attaques (brute force, exploitation Shellshock, scans réseau, etc.) via Internet.

---

## 🧪 Scénarios réalisés

| # | Scénario | Statut |
|---|---|---|
| 1 | Installation Wazuh Manager + Indexer + Dashboard | ✅ |
| 2 | Installation et enrôlement des agents (Windows, Ubuntu) | ✅ |
| 3 | File Integrity Monitoring (FIM) | ✅ |
| 4 | Détection d'attaque brute force (SSH/RDP) | ✅ |
| 5 | Détection Shellshock (CVE-2014-6271) | ✅ |
| 6 | Détection de processus non autorisé | ✅ |
| 7 | Monitoring d'exécution de commandes malveillantes | ✅ |
| 8 | Active Response — blocage automatique SSH | ✅ |
| 9 | Utilisateur Dashboard en lecture seule (Read-Only) | ✅ |
| 10 | Tableau de bord personnalisé (Custom Dashboard) | ✅ |
| 11 | Intégration Sysmon + Wazuh (SIEM avancé Windows) | ✅ |
| 12 | Intégration Snort + Wazuh | ✅ |
| 13 | Intégration Suricata IDS/IPS + Wazuh | ✅ |
| 14 | Règles de détection personnalisées (Custom Rules) | ✅ |
| 15 | Intégration Wazuh + VirusTotal | ✅ |

---

## ⚙️ 1. Installation

### a. Wazuh Manager (serveur central)

```bash
curl -sO https://packages.wazuh.com/4.x/wazuh-install.sh
sudo bash wazuh-install.sh -a
```

À l'issue de l'installation, l'accès au dashboard et les identifiants générés (utilisateur `admin`) sont affichés — **à changer immédiatement** et à ne jamais committer en clair dans le dépôt.

```
Web UI: https://<wazuh-dashboard-ip>:443
```

📸 *Voir [`docs/screenshots/`](docs/screenshots/) pour les captures d'installation et du dashboard.*

### b. Agent Ubuntu

```bash
apt update
apt install wget -y
wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.7.2-1_amd64.deb
apt install -f -y
apt install lsb-release -y
WAZUH_MANAGER='<MANAGER_IP>' dpkg -i wazuh-agent_4.7.2-1_amd64.deb
```

Ou via configuration manuelle dans `/var/ossec/etc/ossec.conf` :

```xml
<client>
  <server>
    <address>MANAGER_IP</address>
    <port>1514</port>
    <protocol>tcp</protocol>
  </server>
</client>
```

```bash
/var/ossec/bin/wazuh-control start
/var/ossec/bin/wazuh-control status
```

### c. Agent Windows

Installation via l'assistant graphique `wazuh-agent.msi` ou en ligne de commande (`msiexec`), en renseignant l'IP du Manager. Vérification du statut `Running` dans le gestionnaire de l'agent Windows.

### d. Démarrage des services

```bash
systemctl start wazuh-manager
systemctl start wazuh-indexer
systemctl start wazuh-dashboard
```

📄 Configurations détaillées : [`configs/wazuh-manager/`](configs/wazuh-manager/), [`configs/wazuh-agent-windows/`](configs/wazuh-agent-windows/), [`configs/wazuh-agent-ubuntu/`](configs/wazuh-agent-ubuntu/)

---

## 🗂️ 2. File Integrity Monitoring (FIM)

Surveillance en temps réel d'un répertoire sensible sur l'agent Windows :

```xml
<syscheck>
  <directories recursion_level="0" restrict="winrm.vbs$">%WINDIR%\SysNative</directories>
  <directories check_all="yes" realtime="yes">C:\Users\Administrator\Desktop\SensitiveData</directories>
</syscheck>
```

- `check_all="yes"` : surveille l'ensemble des attributs du fichier (hash, permissions, propriétaire, taille...) ;
- `realtime="yes"` : détection immédiate (au lieu d'un scan périodique).

Toute création/modification/suppression de fichier dans `SensitiveData` génère une alerte Wazuh visible dans le module **Integrity Monitoring** du dashboard.

📸 Capture : alerte FIM déclenchée après modification d'un fichier test.

---

## 🔐 3. Détection d'attaque Brute Force

Simulation d'une attaque brute force SSH (Ubuntu) / RDP (Windows) depuis la machine attaquante (ex. avec `hydra` ou `crowbar`).

Wazuh détecte les tentatives d'authentification échouées répétées via les règles par défaut (groupe `authentication_failed`, `multiple_authentication_failures`) et déclenche une alerte de sévérité élevée après le seuil défini.

📸 Capture : alerte "Multiple authentication failures" avec l'IP source de l'attaquant.

---

## 🐚 4. Détection Shellshock (CVE-2014-6271)

Détection de tentatives d'exploitation de la vulnérabilité Shellshock via les logs Apache/CGI, en s'appuyant sur les règles Wazuh dédiées (décodeur `web-accesslog` + règle correspondant à la signature `() { :; };`).

📸 Capture : alerte Shellshock générée lors d'une requête HTTP contenant le payload d'exploitation.

---

## 🕵️ 5. Détection de processus non autorisé

Utilisation des capacités de surveillance de processus de Wazuh (via Sysmon sur Windows ou `auditd`/règles personnalisées sur Linux) pour générer une alerte lors du lancement d'un binaire non whitelisté (ex. `nc.exe`, `mimikatz.exe`, `powershell -enc`).

📸 Capture : alerte de processus suspect détecté.

---

## 💻 6. Monitoring d'exécution de commandes malveillantes

Détection de commandes suspectes exécutées sur les hôtes (ex. téléchargement distant via `curl`/`wget`/`certutil`, énumération, désactivation de la défense) grâce à des règles corrélant les logs Sysmon (Event ID 1 — process creation) et les règles Wazuh associées.

📸 Capture : alerte sur exécution de commande malveillante.

---

## 🚫 7. Active Response — Blocage automatique SSH

Configuration d'une réponse active bloquant automatiquement l'adresse IP source après détection d'une attaque brute force SSH, via le script `firewall-drop` de Wazuh.

Extrait `ossec.conf` (Manager) :

```xml
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>5763,5720</rules_id>
  <timeout>600</timeout>
</active-response>
```

Script utilisé : [`scripts/active-response-ssh-block.sh`](scripts/active-response-ssh-block.sh)

📸 Capture : IP bloquée automatiquement (règle iptables/nftables générée) après tentative de brute force.

---

## 👤 8. Utilisateur Dashboard en lecture seule

Création d'un rôle personnalisé dans le Wazuh Dashboard (OpenSearch Security) limitant les permissions à la lecture seule (`readonly`), sans droit de modification des règles, agents ou configurations — utile pour donner un accès de supervision à un tiers sans risque.

📸 Capture : rôle `readonly` créé et utilisateur associé.

---

## 📊 9. Tableau de bord personnalisé

Construction d'un dashboard Wazuh sur mesure (visualisations OpenSearch) regroupant les indicateurs clés du lab : nombre d'alertes par agent, top règles déclenchées, carte des IP attaquantes, timeline des événements critiques.

📸 Capture : dashboard personnalisé.

---

## 🪟 10. Intégration Sysmon + SIEM

Déploiement de **Sysmon** sur l'agent Windows avec une configuration avancée (ex. base SwiftOnSecurity), permettant à Wazuh de collecter une télémétrie fine (création de process, connexions réseau, modifications de registre, chargement de DLL) via le module `<localfile>` pointant vers le canal `Microsoft-Windows-Sysmon/Operational`.

Configuration : [`configs/sysmon/sysmon-config.xml`](configs/sysmon/sysmon-config.xml)

---

## 🐷 11. Intégration Snort + Wazuh

Déploiement de **Snort** en tant que sonde IDS réseau ; les alertes générées (fichier `alert` / `unified2`) sont ingérées par Wazuh via `<localfile>` et corrélées avec les règles de décodage Snort natives de Wazuh.

---

## 🦈 12. Intégration Suricata IDS/IPS + Wazuh

Déploiement de **Suricata** en mode IDS/IPS sur l'agent Ubuntu dédié, avec des règles personnalisées :

```
{% include "rules/local.rules" %}
```
→ voir [`rules/local.rules`](rules/local.rules)

Les logs `eve.json` de Suricata sont transmis à Wazuh via `<localfile>` (format `json`), permettant la corrélation des alertes réseau avec les événements hôtes dans un seul dashboard.

📸 Capture : alertes Suricata visibles dans Wazuh.

---

## 📐 13. Règles de détection personnalisées (Custom Rules)

Ajout de règles sur mesure dans `/var/ossec/etc/rules/local_rules.xml` du Manager, adaptées aux scénarios du lab (ex. détection spécifique Shellshock, seuils de brute force personnalisés, alertes sur fichiers sensibles).

📄 Fichier : [`rules/wazuh-custom-rules.xml`](rules/wazuh-custom-rules.xml)

---

## 🦠 14. Intégration Wazuh + VirusTotal

Configuration de l'intégration native Wazuh-VirusTotal pour vérifier automatiquement la réputation des fichiers détectés par le module FIM (hash soumis à l'API VirusTotal), avec génération d'une alerte si le fichier est identifié comme malveillant.

Extrait `ossec.conf` (Manager) :

```xml
<integration>
  <name>virustotal</name>
  <api_key>VOTRE_CLE_API</api_key>
  <rule_id>550,554</rule_id>
  <alert_format>json</alert_format>
</integration>
```

⚠️ La clé API VirusTotal ne doit jamais être committée en clair — utiliser une variable d'environnement ou un fichier ignoré par `.gitignore`.

---

## 🗂️ Structure du dépôt

```
Wazuh-SIEM-Project/
├── architecture/
│   └── Architecture.png
├── docs/
│   └── screenshots/          # captures pour chaque scénario
├── configs/
│   ├── wazuh-manager/
│   ├── wazuh-agent-windows/
│   ├── wazuh-agent-ubuntu/
│   ├── suricata/
│   └── sysmon/
├── rules/
│   ├── local.rules           # règles Suricata
│   └── wazuh-custom-rules.xml
├── scripts/
│   └── active-response-ssh-block.sh
└── README.md
```

---

## 🧰 Outils utilisés

- **Wazuh 4.7.x** (Manager, Indexer, Dashboard)
- **Sysmon** (SwiftOnSecurity / Olaf Hartong config)
- **Snort** / **Suricata** (IDS/IPS réseau)
- **VirusTotal API**
- **Kali Linux** (machine attaquante)
- **Windows Server** / **Ubuntu Server** (agents)

## ⚠️ Avertissement

Ce projet a été réalisé dans un environnement de lab isolé (machines virtuelles, réseau interne) à des fins strictement pédagogiques. Aucun identifiant, mot de passe ou clé API réel n'est exposé dans ce dépôt.

## 👤 Auteur

**Yassir GAABOUR**
🔗 [GitHub](https://github.com/Yasser-02G)

## 📄 Licence

Distribué sous licence MIT.
