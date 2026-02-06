# openedx-ci
CI overview 
But: Ce document explique comment fonctionne l'intégration continue (CI) minimale fournie et comment résoudre les erreurs courantes.

Comment ça marche

- Les vérifications statiques s'exécutent sur chaque `push` et `pull_request` sur `main` : validation YAML + ShellCheck sur `ops/*.sh`.
- Quand un tag `v*` est poussé (ex: `v1.0.0`), un job supplémentaire construit l'image Docker et la pousse vers GitHub Container Registry (`ghcr.io`).

Emplacement du workflow

- `.github/workflows/ci-and-build.yml`

Comment corriger les échecs fréquents

1) Échec de validation YAML
   - Le workflow signale le fichier et la ligne.
   - Ouvrez le fichier YAML signalé et corrigez la syntaxe (indentation, deux-points, guillemets).
   - Test local rapide : `yamllint <file>` (si installé).

2) ShellCheck trouve des erreurs dans `ops/*.sh`
   - ShellCheck signale les lignes et les recommandations.
   - Corrigez les valeurs non citées, les expansions de variables, et ajoutez `set -euo pipefail` si nécessaire.
   - Test local rapide : `shellcheck ops/build_image.sh`.

3) Échec au build/push d'image sur tag
   - Vérifiez que le workflow dispose des permissions `packages: write`.
   - Pour `ghcr.io`, `GITHUB_TOKEN` doit avoir accès aux packages (vérifier paramètres du repo ou utiliser un PAT dans `secrets` si nécessaire).
   - Vérifiez les logs du job `build_and_push` pour la commande ayant échoué (login, build ou push).

Tests locaux recommandés

- Lancer rapidement la construction locale :

```bash
# construire localement
./ops/build_image.sh -i ghcr.io/OWNER/REPO -r v0.0.0

# construire et pousser (nécessite authentification docker)
./ops/build_image.sh -i ghcr.io/OWNER/REPO -r v0.0.0 -p
```

Support

- Si un échec CI vous bloque, copiez les logs du job et envoyez-les dans l'issue/PR correspondante avec le contexte (commande utilisée, tag, etc.).

