package bot

import (
	"fmt"
	"github.com/bwmarrin/discordgo"
	"math/rand"
	"strings"
	"time"
	"xdn-voting/utils"
)

func RainEmbed(message string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		Type:        "",
		Title:       "Rain in progress",
		Description: message,
		Timestamp:   timeString,
		Color:       0x00ff00,
		Footer:      nil,
		Image:       nil,
		Thumbnail:   nil,
		Video:       nil,
		Provider:    nil,
		Fields:      nil,
	}
	return &genericEmbed
}

func ThunderEmbed(message string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		Type:        "",
		Title:       "Thunder in progress",
		Description: message,
		Timestamp:   timeString,
		Color:       0x00ff00,
		Footer:      nil,
		Image:       nil,
		Thumbnail:   nil,
		Video:       nil,
		Provider:    nil,
		Fields:      nil,
	}
	return &genericEmbed
}

func RainFinishEmbed(message, avatar, username string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		Type:        "",
		Title:       "Rain successfull",
		Description: message,
		Timestamp:   timeString,
		Color:       0x00ff00,
		Footer:      nil,
		Image:       nil,
		Thumbnail:   nil,
		Video:       nil,
		Provider:    nil,
		Author: &discordgo.MessageEmbedAuthor{
			Name:    username,
			URL:     "",
			IconURL: avatar,
		},
		Fields: nil,
	}
	return &genericEmbed
}

func ThunderFinishEmbed(message, avatar, username string) *discordgo.MessageEmbed {
	LoadPictures()
	rand.Seed(time.Now().UnixNano())
	randNum := rand.Intn(len(PictureThunder))

	t := strings.ReplaceAll(message, "rained", "brought Thunder")

	url := fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d", randNum)
	utils.ReportMessage(url)

	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		URL:         "https://t.me/XDNDN",
		Type:        "",
		Title:       "|>>> Join us on our Telegram channel <<<|",
		Description: t,
		Timestamp:   timeString,
		Color:       0xe19624,
		Footer: &discordgo.MessageEmbedFooter{
			Text:         "Thunderstorm finished",
			IconURL:      "",
			ProxyIconURL: "",
		},
		Image: &discordgo.MessageEmbedImage{
			URL: url,
		},
		Thumbnail: nil,
		Video:     nil,
		Provider:  nil,
		Author: &discordgo.MessageEmbedAuthor{
			Name:    username,
			URL:     "",
			IconURL: avatar,
		},
		Fields: nil,
	}
	return &genericEmbed
}

func GenericEmbed(title, message, avatar, username string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		URL:         "",
		Type:        "",
		Title:       "This is a test",
		Description: message,
		Timestamp:   timeString,
		Color:       0x00ff00,
		Footer: &discordgo.MessageEmbedFooter{
			Text:         "This is a test",
			IconURL:      "",
			ProxyIconURL: "",
		},
		Thumbnail: nil,
		Video:     nil,
		Provider:  nil,
		Author: &discordgo.MessageEmbedAuthor{
			Name:    username,
			URL:     "",
			IconURL: avatar,
		},
		Fields: nil,
	}
	return &genericEmbed
}

func AnnEmbed(url, message, username, picture string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		URL:         url,
		Type:        "",
		Title:       "Announcement",
		Description: message,
		Timestamp:   timeString,
		Color:       0x00ff00,
		Footer: &discordgo.MessageEmbedFooter{
			Text:         "Announcement",
			IconURL:      "https://github.com/DigitalNoteXDN/MediaPack/blob/master/XDN/DN2020_circle_hires.png?raw=true",
			ProxyIconURL: "",
		},
		Image: &discordgo.MessageEmbedImage{
			URL: picture,
		},
		Thumbnail: nil,
		Video:     nil,
		Provider:  nil,
		Author: &discordgo.MessageEmbedAuthor{
			Name:    username,
			URL:     "",
			IconURL: "https://github.com/DigitalNoteXDN/MediaPack/blob/master/XDN/DN2020_circle_hires.png?raw=true",
		},
		Fields: nil,
	}
	return &genericEmbed
}

func TipEmbed(userFrom, userTo, amount, avatar, username string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		Type:        "",
		Title:       "Tip successful",
		Description: fmt.Sprintf("User <@%s> tipped <@%s> %s XDN", userFrom, userTo, amount),
		Timestamp:   timeString,
		Color:       0x00ff00,
		Footer:      nil,
		Image:       nil,
		Thumbnail:   nil,
		Video:       nil,
		Provider:    nil,
		Author: &discordgo.MessageEmbedAuthor{
			Name:    username,
			URL:     "",
			IconURL: avatar,
		},
		Fields: nil,
	}
	return &genericEmbed
}

func TipErrorEmbed(error, title string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		Type:        "",
		Title:       title,
		Description: error,
		Timestamp:   timeString,
		Color:       0xEB0000,
		Footer:      nil,
		Image:       nil,
		Thumbnail:   nil,
		Video:       nil,
		Provider:    nil,
		Author: &discordgo.MessageEmbedAuthor{
			Name:    "XDN Tip Bot",
			URL:     "",
			IconURL: "https://cdn.discordapp.com/avatars/1038623597746458644/b4aa43e5d422bcc3b72e49d067d87f73.webp?size=160",
		},
		Fields: nil,
	}
	return &genericEmbed
}

func AskEmbed(description, title string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		Type:        "",
		Title:       title,
		Description: description,
		Timestamp:   timeString,
		Color:       0x00ff00,
		Footer:      nil,
		Image:       nil,
		Thumbnail:   nil,
		Video:       nil,
		Provider:    nil,
		Author: &discordgo.MessageEmbedAuthor{
			Name:    "XDN Tip Bot",
			URL:     "",
			IconURL: "https://cdn.discordapp.com/avatars/1038623597746458644/b4aa43e5d422bcc3b72e49d067d87f73.webp?size=160",
		},
		Fields: nil,
	}
	return &genericEmbed
}

func GiftEmbed(message, picture string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		Type:        "",
		Title:       "",
		Description: message,
		Timestamp:   timeString,
		Color:       0x31BFCA,
		Footer:      nil,
		Image: &discordgo.MessageEmbedImage{
			URL: picture,
		},
		Thumbnail: nil,
		Video:     nil,
		Provider:  nil,
		Author: &discordgo.MessageEmbedAuthor{
			Name:    "XDN Tip Bot",
			URL:     "",
			IconURL: "https://cdn.discordapp.com/avatars/1038623597746458644/b4aa43e5d422bcc3b72e49d067d87f73.webp?size=160",
		},
		Fields: nil,
	}
	return &genericEmbed
}

func WinEmbed(userTo, amount, avatar, username string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		Type:        "",
		Title:       "Gift Bot winner",
		Description: fmt.Sprintf("Congrats <@%s>, you won %s XDN!", userTo, amount),
		Timestamp:   timeString,
		Color:       0x00ff00,
		Footer:      nil,
		Image:       nil,
		Thumbnail:   nil,
		Video:       nil,
		Provider:    nil,
		Author: &discordgo.MessageEmbedAuthor{
			Name:    username,
			URL:     "",
			IconURL: avatar,
		},
		Fields: nil,
	}
	return &genericEmbed
}
