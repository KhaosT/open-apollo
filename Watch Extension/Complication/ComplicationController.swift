//
//  ComplicationController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 11/4/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        var optionalTemplate: CLKComplicationTemplate?
        
        switch complication.family {
        case .modularSmall:
            optionalTemplate = modularSmallComplication()
        case .modularLarge:
            optionalTemplate = modularLargeComplication()
        case .utilitarianSmall:
            optionalTemplate = utilitarianSmallComplication()
        case .utilitarianSmallFlat:
            optionalTemplate = utilitarianSmallFlatComplication()
        case .utilitarianLarge:
            optionalTemplate = utilitarianLargeComplication()
        case .circularSmall:
            optionalTemplate = circularSmallComplication()
        case .extraLarge:
            optionalTemplate = extraLargeComplication()
        case .graphicCorner:
            optionalTemplate = graphicCornerComplication()
        case .graphicBezel:
            optionalTemplate = graphicBezelComplication()
        case .graphicCircular:
            optionalTemplate = graphicCircularComplication()
        case .graphicRectangular:
            optionalTemplate = graphicRectangularComplication()
        @unknown default:
            break
        }
        
        guard let template = optionalTemplate else {
            handler(nil)
            return
        }
        
        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        handler(entry)
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        switch complication.family {
        case .modularSmall:
            handler(modularSmallComplication())
        case .modularLarge:
            handler(modularLargeComplication())
        case .utilitarianSmall:
            handler(utilitarianSmallComplication())
        case .utilitarianSmallFlat:
            handler(utilitarianSmallFlatComplication())
        case .utilitarianLarge:
            handler(utilitarianLargeComplication())
        case .circularSmall:
            handler(circularSmallComplication())
        case .extraLarge:
            handler(extraLargeComplication())
        case .graphicCorner:
            handler(graphicCornerComplication())
        case .graphicBezel:
            handler(graphicBezelComplication())
        case .graphicCircular:
            handler(graphicCircularComplication())
        case .graphicRectangular:
            handler(graphicRectangularComplication())
        default:
            handler(nil)
        }
    }
}

// MARK: - Complication

extension ComplicationController {
    
    private func modularSmallComplication() -> CLKComplicationTemplate {
        if SpotifyPlayer.shared.player.playbackState.isActive {
            let template = CLKComplicationTemplateModularSmallRingImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-Modular-Small")!)
            template.fillFraction = Float(SpotifyPlayer.shared.player.progress)
            template.ringStyle = .closed
            return template
        } else {
            let template = CLKComplicationTemplateModularSmallSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-Modular-Small")!)
            return template
        }
    }
    
    private func modularLargeComplication() -> CLKComplicationTemplate {
        if SpotifyPlayer.shared.player.playbackState.isActive {
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-Modular-Large")!)
            
            template.headerTextProvider = CLKSimpleTextProvider(text: "Apollo")
            template.headerTextProvider.tintColor = Color.green
            
            if let title = SpotifyPlayer.shared.player.currentTrack?.metadata.title {
                template.body1TextProvider = CLKSimpleTextProvider(text: title)
            } else {
                template.body1TextProvider = CLKSimpleTextProvider(text: "-")
            }
            return template
        } else {
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-Modular-Large")!)
            
            template.headerTextProvider = CLKSimpleTextProvider(text: "Apollo")
            template.headerTextProvider.tintColor = Color.green
            template.body1TextProvider = CLKSimpleTextProvider(text: "")
            return template
        }
    }
    
    private func utilitarianSmallComplication() -> CLKComplicationTemplate {
        if SpotifyPlayer.shared.player.playbackState.isActive {
            let template = CLKComplicationTemplateUtilitarianSmallRingImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-Utility-Small")!)
            template.fillFraction = Float(SpotifyPlayer.shared.player.progress)
            template.ringStyle = .closed
            return template
        } else {
            let template = CLKComplicationTemplateUtilitarianSmallSquare()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-Utility-Small")!)
            return template
        }
    }
    
    private func utilitarianSmallFlatComplication() -> CLKComplicationTemplate {
        if SpotifyPlayer.shared.player.playbackState.isActive {
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-Modular-Large")!)
            template.textProvider = CLKSimpleTextProvider(text: durationStringForDuration(SpotifyPlayer.shared.player.currentTime))
            return template
        } else {
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-Modular-Large")!)
            template.textProvider = CLKSimpleTextProvider(text: "Apollo")
            return template
        }
    }
    
    private func utilitarianLargeComplication() -> CLKComplicationTemplate {
        if SpotifyPlayer.shared.player.playbackState.isActive {
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-Modular-Large")!)
            if let title = SpotifyPlayer.shared.player.currentTrack?.metadata.title {
                template.textProvider = CLKSimpleTextProvider(text: title)
            } else {
                template.textProvider = CLKSimpleTextProvider(text: durationStringForDuration(SpotifyPlayer.shared.player.currentTime))
            }
            return template
        } else {
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-Modular-Large")!)
            template.textProvider = CLKSimpleTextProvider(text: "Apollo")
            return template
        }
    }
    
    private func circularSmallComplication() -> CLKComplicationTemplate {
        if SpotifyPlayer.shared.player.playbackState.isActive {
            let template = CLKComplicationTemplateCircularSmallRingImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-Circular")!)
            template.fillFraction = Float(SpotifyPlayer.shared.player.progress)
            template.ringStyle = .closed
            return template
        } else {
            let template = CLKComplicationTemplateCircularSmallSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-Circular")!)
            return template
        }
    }
    
    private func extraLargeComplication() -> CLKComplicationTemplate {
        if SpotifyPlayer.shared.player.playbackState.isActive {
            let template = CLKComplicationTemplateExtraLargeRingImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-ExtraLarge")!)
            template.fillFraction = Float(SpotifyPlayer.shared.player.progress)
            template.ringStyle = .closed
            return template
        } else {
            let template = CLKComplicationTemplateExtraLargeSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication-ExtraLarge")!)
            return template
        }
    }
    
    private func graphicCornerComplication() -> CLKComplicationTemplate {
        if SpotifyPlayer.shared.player.playbackState.isActive {
            let template = CLKComplicationTemplateGraphicCornerGaugeImage()
            template.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: Color.green, fillFraction: Float(SpotifyPlayer.shared.player.progress))
            template.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication-Graphic-Corner-Small")!)
            return template
        } else {
            let template = CLKComplicationTemplateGraphicCornerCircularImage()
            template.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication-Graphic-Corner-Circular")!)
            return template
        }
    }
    
    private func graphicBezelComplication() -> CLKComplicationTemplate {
        if SpotifyPlayer.shared.player.playbackState.isActive {
            let template = CLKComplicationTemplateGraphicBezelCircularText()
            template.circularTemplate = graphicCircularComplication()
            if let title = SpotifyPlayer.shared.player.currentTrack?.metadata.title {
                template.textProvider = CLKSimpleTextProvider(text: title)
            }
            return template
        } else {
            let template = CLKComplicationTemplateGraphicBezelCircularText()
            template.circularTemplate = graphicCircularComplication()
            return template
        }
    }
    
    private func graphicCircularComplication() -> CLKComplicationTemplateGraphicCircular {
        if SpotifyPlayer.shared.player.playbackState.isActive {
            let template = CLKComplicationTemplateGraphicCircularClosedGaugeImage()
            template.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: Color.green, fillFraction: Float(SpotifyPlayer.shared.player.progress))
            template.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication-Graphic-Circular-Small")!)
            return template
        } else {
            let template = CLKComplicationTemplateGraphicCircularImage()
            template.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication-Graphic-Circular-Circular")!)
            return template
        }
    }
    
    private func graphicRectangularComplication() -> CLKComplicationTemplate {
        if SpotifyPlayer.shared.player.playbackState.isActive {
            let template = CLKComplicationTemplateGraphicRectangularTextGauge()
            template.headerImageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication-Graphic-Rectangular")!)
            
            template.headerTextProvider = CLKSimpleTextProvider(text: "Now Playing")
            template.headerTextProvider.tintColor = UIColor.lightGray
            
            if let title = SpotifyPlayer.shared.player.currentTrack?.metadata.title {
                template.body1TextProvider = CLKSimpleTextProvider(text: title)
            } else {
                template.body1TextProvider = CLKSimpleTextProvider(text: "-")
            }
            
            template.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: Color.green, fillFraction: Float(SpotifyPlayer.shared.player.progress))
            
            return template
        } else {
            let template = CLKComplicationTemplateGraphicRectangularStandardBody()
            template.headerImageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication-Graphic-Rectangular")!)
            
            template.headerTextProvider = CLKSimpleTextProvider(text: "Apollo")
            template.headerTextProvider.tintColor = Color.green
            
            template.body1TextProvider = CLKSimpleTextProvider(text: "")
            return template
        }
    }
}

// MARK: - Helper

extension ComplicationController {
    
    private func durationStringForDuration(_ duration: Double) -> String {
        let hours = Int(duration / 3600.0)
        let minutes = Int(duration / 60.0) % 60
        let seconds = Int(duration) % 60
        
        if hours != 0 {
            let text = String(format: "%u:%02u:%02u", hours, minutes, seconds)
            return text
        } else {
            let text = String(format: "%u:%02u", minutes, seconds)
            return text
        }
    }
}
