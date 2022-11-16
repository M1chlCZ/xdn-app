package bot

import (
	"fmt"
	"github.com/bwmarrin/discordgo"
	"time"
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
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		URL:         "https://t.me/XDNDN",
		Type:        "",
		Title:       "Join us on our Telegram channel",
		Description: message,
		Timestamp:   timeString,
		Color:       0x00ff00,
		Footer: &discordgo.MessageEmbedFooter{
			Text:         "Thunderstorm finished",
			IconURL:      "",
			ProxyIconURL: "",
		},
		Image: &discordgo.MessageEmbedImage{
			URL: "https://abload.de/img/thunder9odaz.png",
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
