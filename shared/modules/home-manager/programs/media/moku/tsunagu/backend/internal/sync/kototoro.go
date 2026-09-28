package sync

import (
	"context"
	"fmt"
	"log"

	"tsunagu/backend/internal/repository"
	"tsunagu/backend/internal/sandbox"
	sandboxv1 "tsunagu/backend/internal/sandbox/gen/sandbox/v1"
)

// A Kototoro parser plugin is one repo entry holding every site. The sandbox lists the
// parsers when asked to load the bare package id, and each becomes its own extension
// ("<package>.<SOURCE>") pointing at the same plugin jar.
const kototoroPackage = "org.skepsun.kototoro.parsers"

func (s *Syncer) SetSandbox(sc *sandbox.SupervisedClient) { s.sandbox = sc }

func (s *Syncer) expandBundles(ctx context.Context, parsed []repository.ParsedExtension) []repository.ParsedExtension {
	out := make([]repository.ParsedExtension, 0, len(parsed))
	for _, ext := range parsed {
		if ext.PackageName != kototoroPackage {
			out = append(out, ext)
			continue
		}
		expanded, err := s.expandKototoro(ctx, ext)
		if err != nil {
			log.Printf("kototoro: listing parsers in %s %s: %v", ext.PackageName, ext.VersionName, err)
			out = append(out, ext)
			continue
		}
		out = append(out, expanded...)
	}
	return out
}

func (s *Syncer) expandKototoro(ctx context.Context, ext repository.ParsedExtension) ([]repository.ParsedExtension, error) {
	if s.sandbox == nil {
		return nil, fmt.Errorf("sandbox not available")
	}
	url := ext.JarURL
	if url == "" {
		url = ext.ApkURL
	}
	path, err := repository.DownloadExtensionFile(s.cacheDir, ext.PackageName, ext.VersionName, url, "jar")
	if err != nil {
		return nil, err
	}
	c, err := s.sandbox.Ensure(ctx)
	if err != nil {
		return nil, err
	}
	resp, err := c.LoadExtensions(ctx, []*sandboxv1.ExtensionToLoad{{ExtensionId: ext.PackageName, JarPath: path}})
	if err != nil {
		return nil, err
	}
	if len(resp.GetExtensions()) == 0 {
		return nil, fmt.Errorf("plugin lists no parsers")
	}
	out := make([]repository.ParsedExtension, 0, len(resp.GetExtensions()))
	for _, p := range resp.GetExtensions() {
		contentType := "manga"
		if p.GetContentType() == sandboxv1.ContentType_ANIME {
			contentType = "anime"
		}
		out = append(out, repository.ParsedExtension{
			Name:        p.GetName(),
			PackageName: p.GetId(),
			ApkURL:      url,
			JarURL:      url,
			IconURL:     ext.IconURL,
			VersionName: ext.VersionName,
			Lang:        p.GetLang(),
			ContentType: contentType,
			IsNsfw:      ext.IsNsfw,
		})
	}
	return out, nil
}
