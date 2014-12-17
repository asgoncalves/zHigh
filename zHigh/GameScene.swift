//
//  GameScene.swift
//  zHigh
//
//  Created by Sergio Goncalves on 14.12.14.
//  Copyright (c) 2014 zalando. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    // GAME OBJECTS
    var pipes: [Obstacle] = []
    var mainPipe: Obstacle = Obstacle()
    var hero: SKSpriteNode = SKSpriteNode()
    var scoreLabel: SKLabelNode = SKLabelNode(fontNamed: "System-Bold")

    // BACKGROUND
    var background1: SKSpriteNode = SKSpriteNode()
    var background2: SKSpriteNode = SKSpriteNode()
    
    // GAME STATE
    var previousOpeningLocation: Int = 50
    var isMoving: Bool = false
    var score: Int = 0

    override func didMoveToView(view: SKView) {
        initializeBackground()
        initializeWorld()
        initializeHero()
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        
        // first touch should start the game
        if (!hero.physicsBody!.dynamic) {
            
            // first always spawns in the middle
            spawnPipeRow(0)
            
            // set the body to dynamic
            hero.physicsBody!.dynamic = true
            
            // initialize with a bit velocity up
            hero.physicsBody!.velocity = CGVectorMake(0, 175)
            
            // update to moving
            isMoving = true
            
        } else if (isMoving) {
            // if it is already moving
            var vel: Float = 200
            
            // if it is too high on the top of the screen - the jump is less
            if (self.view!.bounds.size.height - hero.position.y < 85)
            {
                // get the new velocity value
                vel -= 85.0 - Float(self.view!.bounds.size.height - hero.position.y)
            }
            
            // jump
            hero.physicsBody!.velocity = CGVectorMake(0, CGFloat(vel))
        }
    }
   
    /** Updates the game state **/
    override func update(currentTime: CFTimeInterval) {
        
        // only update if is moving and the pipes were initialized
        if (isMoving && self.pipes.count > 0) {
            
            // update rotation
            let velocity_y = self.hero.physicsBody?.velocity.dy
            self.hero.zRotation = velocity_y! * (velocity_y < 0 ? 0.003 : 0.001)
            
            // each pipe needs to be updated
            for pipe in pipes {

                // update pipe position
                pipe.position.x -= CGFloat(SPEED_CONFIGURATION)
                
                if ((pipe.position.x + pipe.size.width/2) < 0) {
                    pipe.removeFromParent()
                }
                
                if (pipe.position.x < self.hero.position.x && pipe.isScorable && !pipe.isPointAdded) {
                    score++;
                    pipe.isPointAdded = true
                    scoreLabel.text = "\(score)"
                }
            }
            
            let lastPipe = pipes[pipes.count - 1]
            
            // generate new pipe if the last one is already inside the screen
            if (lastPipe.position.x < size.width - lastPipe.size.width * 2.0) {
                spawnPipeRow(generateLocationOfNextOpening())
            }
            
            // update background
            background1.position.x -= CGFloat(SPEED_CONFIGURATION/0.5)
            background2.position.x -= CGFloat(SPEED_CONFIGURATION/0.5)
            
            println("")
            
            //if (background1.position.x <= -self.view!.bounds.size.width * 2.0)
            if (background1.position.x <= -((background1.size.width / 1.13) + (self.view!.bounds.width / 2))) {
                background1.position.x = (background1.size.width / 1.13) - (self.view!.bounds.width / 2) + 2 // +2 for safety margin
            }
            
            if (background2.position.x <= -((background2.size.width / 1.13) + (self.view!.bounds.width / 2))) {
                background2.position.x = (background2.size.width / 1.13) - (self.view!.bounds.width / 2) + 2 // +2 for safety margin
            }
        }
    }
    
    /** Creates more pipe rows **/
    func spawnPipeRow(xPosition: Int) {
        let yPosition = Float(xPosition) + PIPE_SPACE_CONFIGURATION / 2

        let bottomPipe = mainPipe.copy() as Obstacle;
        let topPipe    = mainPipe.copy() as Obstacle;
  
        let screenWidth = size.width

        addBottomPipe(bottomPipe, x: Float(screenWidth), y: yPosition)
        addTopPipe(topPipe, x: Float(screenWidth), y: yPosition + PIPE_SPACE_CONFIGURATION)
        
        bottomPipe.physicsBody = SKPhysicsBody(rectangleOfSize: bottomPipe.size)
        bottomPipe.physicsBody!.dynamic = false
        bottomPipe.physicsBody!.contactTestBitMask = BIRD_CATEGORY
        bottomPipe.physicsBody!.collisionBitMask = BIRD_CATEGORY
        bottomPipe.texture = SKTexture(imageNamed: BOTTOM_PIPE_IMAGE)
        bottomPipe.texture!.filteringMode = SKTextureFilteringMode.Nearest
        
        topPipe.physicsBody = SKPhysicsBody(rectangleOfSize: topPipe.size)
        topPipe.physicsBody!.dynamic = false
        topPipe.physicsBody!.contactTestBitMask = BIRD_CATEGORY
        topPipe.physicsBody!.collisionBitMask = BIRD_CATEGORY
        topPipe.texture = SKTexture(imageNamed: TOP_PIPE_IMAGE)
        topPipe.texture!.filteringMode = SKTextureFilteringMode.Nearest
        
        pipes.append(bottomPipe)
        pipes.append(topPipe)
        
        addChild(bottomPipe)
        addChild(topPipe)
    }
    
    /** Adds bottom pipe to the world **/
    func addBottomPipe(node: Obstacle, x: Float, y: Float) {
        let xPosition = (Float(node.size.width) / 2) + x
        let yPosition = Float(size.height) / 2 - (Float(node.size.height) / 2) + y

        node.isScorable = true
        node.position.x = CGFloat(xPosition)
        node.position.y = CGFloat(yPosition)
    }

    /** Adds top pipe to the world **/
    func addTopPipe(node: Obstacle, x: Float, y: Float) {
        let xPosition = (Float(node.size.width) / 2) + x
        let yPosition = Float(size.height) / 2 + (Float(node.size.height) / 2) + y
        
        node.position.x = CGFloat(xPosition)
        node.position.y = CGFloat(yPosition)
    }
    
    /** Generates the next opening location for the pipes */
    func generateLocationOfNextOpening() -> Int {
        var offsetForNextPipe = previousOpeningLocation + randRange(MINIMUM_LOCATION_OFFSET, upper: MAXIMUM_LOCATION_OFFSET);
        
        if (offsetForNextPipe > MAXIMUM_LOCATION_OFFSET) {
            offsetForNextPipe = MAXIMUM_LOCATION_OFFSET
        }
        
        if (offsetForNextPipe < MINIMUM_LOCATION_OFFSET) {
            offsetForNextPipe = MINIMUM_LOCATION_OFFSET
        }
        
        // update the previous opening location
        self.previousOpeningLocation = offsetForNextPipe
        
        // return the new position for the opening
        return offsetForNextPipe
    }
    
    /** Generates a random number between the two ranges */
    func randRange (lower: Int , upper: Int) -> Int {
        return lower + Int(arc4random_uniform(UInt32(upper - lower + 1)))
    }
    
    /** Initializes the hero */
    func initializeHero() {
        self.hero = SKSpriteNode(color: UIColor.blackColor(), size: CGSize(width: 30, height: 30))
        self.hero.physicsBody = SKPhysicsBody(circleOfRadius: 15)
        self.hero.physicsBody!.dynamic = false
        self.hero.physicsBody!.collisionBitMask = PIPE_CATEGORY
        self.hero.physicsBody!.contactTestBitMask = PIPE_CATEGORY
        self.hero.zPosition = 50
        self.hero.position = CGPoint(x: 150, y: 500)
        self.hero.texture = SKTexture(imageNamed: HERO_IMAGE)
        self.hero.texture!.filteringMode = SKTextureFilteringMode.Nearest
        
        self.addChild(self.hero)
    }
    
    /** Initializes the background */
    func initializeBackground() {
        self.background1 = SKSpriteNode(imageNamed: BACKGROUND_IMAGE)
        self.background1.position.x = self.view!.bounds.size.width * 0.5
        self.background1.position.y = self.view!.bounds.size.height * 0.5
        self.background1.texture?.filteringMode = SKTextureFilteringMode.Nearest
        
        self.background1.size.height = self.view!.bounds.height * 1.13
        
        self.background2 = SKSpriteNode(imageNamed: BACKGROUND_IMAGE)
        self.background2.position.x = self.view!.bounds.size.width * 1.5
        self.background2.position.y = self.view!.bounds.size.height * 0.5
        self.background2.texture?.filteringMode = SKTextureFilteringMode.Nearest
        
        self.background2.size.height = self.view!.bounds.height * 1.13

        
        // score
        scoreLabel.position.x = self.view!.bounds.width/2
        scoreLabel.position.y = self.view!.bounds.height - 100
        
        scoreLabel.text = "0"
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        
        addChild(self.background1)
        addChild(self.scoreLabel)
    }
    
    /** Initializes the world */
    func initializeWorld() {
        
        // initialize pipe
        self.mainPipe = Obstacle(color: UIColor.blackColor(), size: CGSize(width: size.width/6, height: 680))
        
        // configure physics
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVectorMake(0, -5.0)
        
        score = 0
    }
    
    /** Handles colisions */
    func didBeginContact(contact: SKPhysicsContact) {
        if (isMoving) {
            isMoving = false
            hero.physicsBody?.velocity = CGVectorMake(0, 0)
        }
        
        for pipe in pipes {
            pipe.physicsBody = nil
        }
        
        NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("addRestartButton"), userInfo: nil, repeats: false)
    }
    
    func addRestartButton() {
        // button to restart
        var button: GGButton = GGButton(defaultButtonImage: "play_button2", activeButtonImage: "play_button2", buttonAction: restartGame)
        button.position = CGPointMake(self.frame.width / 2, self.frame.height / 6)
        self.addChild(button)
    }
    
    /** Restarts the elements */
    func restartGame() {
        self.removeAllChildren()
        hero.removeFromParent()
        background1.removeAllChildren()
        background1.removeFromParent()
        pipes.removeAll(keepCapacity: false)
        
        initializeBackground()
        initializeWorld()
        initializeHero()
    }
}