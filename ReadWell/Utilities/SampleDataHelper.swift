import Foundation
import CoreData

class SampleDataHelper {
    
    static func addSampleTexts(context: NSManagedObjectContext) {
        // Check if we already have texts
        let request: NSFetchRequest<ReadingText> = ReadingText.fetchRequest()
        
        do {
            let existingTexts = try context.fetch(request)
            if !existingTexts.isEmpty {
                print("📚 Sample texts already exist")
                return
            }
        } catch {
            print("Error checking for existing texts: \(error)")
        }
        
        // Sample texts for different grade levels (12 texts total, 2 per grade 1-6)
        let samples = [
            (
                title: "The Helpful Dolphin",
                content: """
                Once upon a time, there was a friendly dolphin named Splash. Splash lived in the ocean with many fish friends. One day, a small fish got caught in a net. Splash saw the fish struggling and knew he had to help. He used his strong nose to push the net until it opened. The little fish swam free! All the fish thanked Splash for being so brave and kind.
                """,
                gradeLevel: 2,
                questions: [
                    ("What is the dolphin's name?", "Splash,Flipper,Bubbles,Wave", "Splash", "The story tells us the dolphin's name is Splash."),
                    ("What problem did the small fish have?", "It was hungry,It was lost,It was caught in a net,It was scared", "It was caught in a net", "The story says a small fish got caught in a net."),
                    ("How did Splash help the fish?", "He called for help,He cut the net,He pushed the net with his nose,He gave the fish food", "He pushed the net with his nose", "Splash used his strong nose to push the net until it opened.")
                ]
            ),
            (
                title: "The Magic Garden",
                content: """
                Emma loved spending time in her grandmother's garden. Every summer, she would visit and help water the plants. One morning, Emma noticed something strange. The flowers were glowing with a soft, golden light! Her grandmother smiled and said, "This garden is special. It blooms extra bright when it's cared for with love." Emma realized that kindness makes everything more beautiful. From that day on, she took care of her own garden at home, and it too began to glow.
                """,
                gradeLevel: 3,
                questions: [
                    ("Where does Emma visit in the summer?", "Her friend's house,Her grandmother's garden,The park,The beach", "Her grandmother's garden", "The story says Emma visits her grandmother's garden every summer."),
                    ("What was special about the flowers?", "They were glowing,They were very big,They smelled sweet,They changed colors", "They were glowing", "Emma noticed the flowers were glowing with a soft, golden light."),
                    ("What makes the garden glow?", "Sunshine,Water,Love and care,Magic dust", "Love and care", "The grandmother said the garden blooms extra bright when cared for with love.")
                ]
            ),
            (
                title: "The Robot's First Day",
                content: """
                R2-B7 was a new robot at Greenfield Elementary School. He was programmed to help students learn, but he was nervous about his first day. When he entered the classroom, some students laughed because he spoke in a robotic voice. R2-B7 felt sad and didn't know if he belonged there. Then a girl named Maya came up to him and said, "Don't worry, everyone is different, and that's what makes us special!" She showed him around the school and introduced him to her friends. By the end of the day, R2-B7 had learned an important lesson: being different is okay, and true friends accept you for who you are.
                """,
                gradeLevel: 4,
                questions: [
                    ("What is the robot's name?", "R2-D2,R2-B7,C-3PO,BB-8", "R2-B7", "The story tells us the robot's name is R2-B7."),
                    ("Why did some students laugh at R2-B7?", "He was clumsy,He spoke in a robotic voice,He looked funny,He made jokes", "He spoke in a robotic voice", "Students laughed because he spoke in a robotic voice."),
                    ("Who helped R2-B7 feel better?", "The teacher,His programmer,Maya,The principal", "Maya", "A girl named Maya came up to him and helped him feel welcome."),
                    ("What lesson did R2-B7 learn?", "Robots are better than humans,Being different is okay,School is hard,Always be quiet", "Being different is okay", "R2-B7 learned that being different is okay and true friends accept you.")
                ]
            ),
            (
                title: "The Mystery of the Missing Books",
                content: """
                The school library was usually a quiet, peaceful place, but this week it was buzzing with whispers and worried looks. Books were disappearing from the shelves, and no one knew why. The librarian, Mrs. Chen, was very concerned. She asked the students to help solve the mystery. A group of fifth graders formed a detective club. They interviewed students, checked the library records, and even stayed after school to watch. Finally, they discovered that a family of mice had made a cozy nest behind the shelves. The mice were using torn pages for bedding! The students carefully relocated the mice to a safe outdoor home and returned the books. Mrs. Chen praised them for their problem-solving skills and compassion for all creatures.
                """,
                gradeLevel: 5,
                questions: [
                    ("What was the problem in the library?", "It was too noisy,Books were disappearing,The computers were broken,It was too crowded", "Books were disappearing", "Books were disappearing from the shelves."),
                    ("Who helped solve the mystery?", "The principal,A group of fifth graders,The janitor,The police", "A group of fifth graders", "A group of fifth graders formed a detective club to solve it."),
                    ("What caused the books to disappear?", "Students were stealing them,A family of mice,Water damage,They were misplaced", "A family of mice", "A family of mice had made a nest and were using torn pages."),
                    ("How did the students handle the situation?", "They threw the mice away,They relocated the mice safely,They kept the mice as pets,They ignored the mice", "They relocated the mice safely", "The students carefully relocated the mice to a safe outdoor home.")
                ]
            ),
            (
                title: "The Lost Puppy",
                content: """
                Lily was walking home from school when she heard a soft cry. She looked down and saw a small puppy with brown spots. The puppy had no collar. Lily picked up the puppy and took it home. Her mom helped her make signs that said "Found Puppy." They put the signs around the neighborhood. The next day, a little boy came to their door. "That's my puppy, Buddy!" he said with a big smile. Lily was happy to help Buddy find his home.
                """,
                gradeLevel: 1,
                questions: [
                    ("What did Lily hear on her way home?", "A bird singing,A soft cry,A car horn,Music", "A soft cry", "Lily heard a soft cry from the lost puppy."),
                    ("What did the puppy look like?", "White with black spots,All black,Brown with spots,Gray", "Brown with spots", "The story says the puppy was small with brown spots."),
                    ("How did Lily help find the puppy's owner?", "She called the police,She made signs,She put it on TV,She asked her teacher", "She made signs", "Lily and her mom made 'Found Puppy' signs.")
                ]
            ),
            (
                title: "The Rainy Day Garden",
                content: """
                It rained all week. Sam looked out the window feeling sad. He wanted to play outside. Then Mom said, "Let's put on our rain boots!" They went outside and jumped in puddles. Sam noticed something wonderful. The flowers looked bigger and brighter than before! "Rain helps plants grow," Mom explained. Sam smiled. Now he liked rainy days too. They helped his garden become beautiful.
                """,
                gradeLevel: 1,
                questions: [
                    ("How did Sam feel at first?", "Happy,Excited,Sad,Angry", "Sad", "Sam felt sad because it rained all week."),
                    ("What did Sam and his mom wear?", "Umbrellas,Rain boots,Hats,Sunglasses", "Rain boots", "Mom told Sam to put on rain boots."),
                    ("What did Sam learn about rain?", "It's cold,It helps plants grow,It's fun,It makes puddles", "It helps plants grow", "Mom explained that rain helps plants grow.")
                ]
            ),
            (
                title: "The Busy Ant",
                content: """
                Annie the ant was very small, but she was mighty! Every day, she carried food that was bigger than herself. Other insects would ask, "Annie, why do you work so hard?" Annie would say, "I'm preparing for winter!" The grasshopper laughed and played all summer. When winter came, Annie had plenty of food in her anthill. The grasshopper was hungry and cold. Annie shared her food with him, and the grasshopper learned an important lesson about hard work and preparation.
                """,
                gradeLevel: 2,
                questions: [
                    ("What makes Annie special?", "She's big,She's colorful,She works hard,She can fly", "She works hard", "Annie works hard carrying food bigger than herself."),
                    ("What was Annie preparing for?", "Summer,Winter,Spring,Fall", "Winter", "Annie said she was preparing for winter."),
                    ("What lesson did the grasshopper learn?", "To play more,To work hard,To sleep late,To be lazy", "To work hard", "The grasshopper learned about hard work and preparation.")
                ]
            ),
            (
                title: "The Recycling Hero",
                content: """
                Carlos noticed his school threw away a lot of trash. He had an idea to help the Earth. Carlos talked to his teacher about starting a recycling program. Together, they set up bins for paper, plastic, and cans. Carlos made colorful posters showing what goes in each bin. At first, only a few students used them. But Carlos didn't give up. He gave a presentation to every class explaining why recycling matters. Soon, the whole school was recycling! The principal gave Carlos a certificate for being an environmental hero. Carlos proved that one person can make a big difference.
                """,
                gradeLevel: 4,
                questions: [
                    ("What problem did Carlos notice?", "Too much homework,Too much trash,Not enough books,Broken computers", "Too much trash", "Carlos noticed his school threw away a lot of trash."),
                    ("What did Carlos set up at school?", "Vending machines,Recycling bins,Water fountains,Book shelves", "Recycling bins", "Carlos and his teacher set up bins for paper, plastic, and cans."),
                    ("How did Carlos convince others to recycle?", "He paid them,He gave presentations,He yelled at them,He sent emails", "He gave presentations", "Carlos gave presentations to every class."),
                    ("What did the principal give Carlos?", "Money,A trophy,A certificate,A medal", "A certificate", "The principal gave Carlos a certificate for being an environmental hero.")
                ]
            ),
            (
                title: "The Science Fair Surprise",
                content: """
                Maria loved science, but she wasn't confident about her science fair project. While other students were building volcanoes and solar systems, Maria decided to study how plants respond to music. For three weeks, she played different types of music to three identical plants. One heard classical music, one heard rock music, and one heard no music at all. She carefully measured their growth and took detailed notes. On science fair day, Maria nervously presented her findings: the plant that heard classical music grew the tallest! The judges were impressed by her original thinking and careful observations. Maria won first place and learned that creativity and curiosity are just as important as fancy equipment.
                """,
                gradeLevel: 5,
                questions: [
                    ("What was unique about Maria's project?", "It was about volcanoes,It studied plants and music,It was about space,It used computers", "It studied plants and music", "Maria studied how plants respond to different types of music."),
                    ("How many plants did Maria use in her experiment?", "Two,Three,Four,Five", "Three", "Maria used three identical plants for her experiment."),
                    ("Which plant grew the tallest?", "The one with no music,The one with rock music,The one with classical music,They all grew the same", "The one with classical music", "The plant that heard classical music grew the tallest."),
                    ("What lesson did Maria learn?", "Science is boring,Creativity matters,Always copy others,Equipment is most important", "Creativity matters", "Maria learned that creativity and curiosity are as important as fancy equipment.")
                ]
            ),
            (
                title: "The Digital Citizen",
                content: """
                Thirteen-year-old Jake was excited when he got his first smartphone. He immediately joined several social media platforms and started posting photos and comments. One day, Jake posted a joke about a classmate without thinking. The next day at school, he discovered that the classmate was hurt by his post. Jake felt terrible. He apologized in person and deleted the post, but he realized the damage was already done. Jake's experience taught him an important lesson about digital citizenship. He learned that everything posted online can affect real people's feelings and lives. Now Jake thinks carefully before posting anything. He asks himself: "Is it true? Is it kind? Is it necessary?" Jake started a club at school to teach others about responsible internet use. His message was simple: treat others online the way you want to be treated in person.
                """,
                gradeLevel: 6,
                questions: [
                    ("What did Jake get that made him excited?", "A computer,A smartphone,A tablet,A camera", "A smartphone", "Jake was excited when he got his first smartphone."),
                    ("What mistake did Jake make?", "He broke his phone,He posted a hurtful joke,He lost his password,He skipped school", "He posted a hurtful joke", "Jake posted a joke about a classmate that hurt their feelings."),
                    ("What three questions does Jake now ask before posting?", "Is it true, kind, and necessary?,Is it funny, cool, and popular?,Is it short, simple, and clear?,Is it new, unique, and creative?", "Is it true, kind, and necessary?", "Jake asks: Is it true? Is it kind? Is it necessary?"),
                    ("What did Jake create at school?", "A website,A blog,A club about responsible internet use,A social media account", "A club about responsible internet use", "Jake started a club to teach others about responsible internet use.")
                ]
            ),
            (
                title: "The Community Garden Project",
                content: """
                When the old grocery store in their neighborhood closed down, many families struggled to find fresh vegetables. Sixth-grader Aisha noticed that her elderly neighbor, Mrs. Johnson, had to take two buses just to buy fresh produce. Aisha decided to do something about it. She researched community gardens and presented her idea to the city council. With their approval and help from local volunteers, they transformed an empty lot into a thriving community garden. Aisha organized workshops teaching people how to grow vegetables, compost, and save seeds. The garden became more than just a source of food—it became a gathering place where neighbors of different backgrounds worked together, shared recipes, and built friendships. Aisha's initiative not only solved a practical problem but also strengthened the bonds in her community. She demonstrated that young people can be powerful agents of positive change.
                """,
                gradeLevel: 6,
                questions: [
                    ("What problem did the neighborhood face?", "No schools,No parks,Hard to get fresh vegetables,Too much traffic", "Hard to get fresh vegetables", "When the grocery store closed, families struggled to find fresh vegetables."),
                    ("Who inspired Aisha to take action?", "Her teacher,Her neighbor Mrs. Johnson,Her parents,The mayor", "Her neighbor Mrs. Johnson", "Aisha noticed Mrs. Johnson had to take two buses to buy fresh produce."),
                    ("Where did Aisha present her idea?", "At school,On TV,To the city council,At church", "To the city council", "Aisha presented her community garden idea to the city council."),
                    ("What did the garden become besides a food source?", "A playground,A gathering place for the community,A school,A store", "A gathering place for the community", "The garden became a gathering place where neighbors worked together and built friendships.")
                ]
            )
        ]
        
        // Create texts and questions
        for sample in samples {
            let text = ReadingText(context: context)
            text.id = UUID()
            text.title = sample.title
            text.content = sample.content
            text.gradeLevel = Int16(sample.gradeLevel)
            text.language = "en"
            text.category = "Fiction"
            text.dateAdded = Date()
            
            // Add questions
            for (index, questionData) in sample.questions.enumerated() {
                let question = ComprehensionQuestion(context: context)
                question.id = UUID()
                question.question = questionData.0
                question.questionType = "multipleChoice"
                question.options = questionData.1
                question.correctAnswer = questionData.2
                question.explanation = questionData.3
                question.orderIndex = Int16(index)
                question.text = text
            }
        }
        
        // Save all sample data
        do {
            try context.save()
            print("✅ Successfully created \(samples.count) sample texts with questions (Grades 1-6)")
        } catch {
            print("❌ Error saving sample texts: \(error)")
        }
    }
}

