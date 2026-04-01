# Decision record

Here I listed the choices I made.

## Architecture

For this project I followed the usual convention for Ruby libraries ([for example](https://github.com/rubygems/bundler)), where every Namespace has an entrypoint.

In this project, our root module `TravelManager` has three uses: 
- Creates the global logger. This could be moved to a Singleton class if the project grew. 
- Creates the global exceptions. This could be moved to an CustomExceptions module if the project grew.
- Public facade for the Itinerary class. This keeps the module as the only entry point, making the calls agnostic to the actual Itinerary class. This is specially helpful as the library evolves, we don't need to change the CLI (`main.rb`).

### Library structure 

I tried to make the names as descriptive as possible. 

- **Segment:** single travel or hostel stay.
- **Trip:** group of sorted segments, with a single destination.

- **FileReader:** reads the input file of the user.
- **Parser:** transforms the text lines into Segments.
- **TripBuilder:** sorts the segments by Trip destination and based location of the user.
- **TextFormatter:** transforms Trips into text, in order to be displayed to the user.

- **Itinerary:** acts as the main controller. It routes the rest of the classes.

- **SegmentType:** single source of truth of segment types.
- **TimeUtils:** utility class to work with date and times.

### Modularity

The library is mostly procedural as it's a clear pipeline (Input File -> Parsed into Segments -> Sorted into Trips -> Formatted as text).

More classes can be added to replace some of the logic of the Itinerary, or even create new controllers for different use cases. For example, we could create a JsonReader, PDFFormatter or even a HotelBuilder if our itinerary is just made of hotels, airbn's, etc ("Camino de Santiago Manager" :D). We could have TextItinerary, PDFItinerary, JSONItinerary...

We could even use inversion of dependencies to make the Itinerary agnostic to the implementations: `self.generate(input_file, based, parser: Parser, formatter: PDFFormatter)`. And delegate that to the CLI.

## Implementation decisions
### Reservation lines

In the input file we can see several `RESERVATION` lines. Apparently they group round-trip reservations.

I decided to ignore these lines and treat every segment individually. The possible issue with this approach would be choosing the wrong segments for the same trips. However, given that we have the specific date and time for each one, I couldn't figure out a way to get the wrong output.

### Connections

Connection flights are useful to get the destination of the trip. Without them, it's almost impossible to know programmatically where is the user heading to:

```
Flight from SVQ to BCN at 2023-03-02 06:40 to 09:10
Flight from BCN to NYC at 2023-03-02 15:00 to 22:45
Hotel at NYC on 2023-03-02 to 2023-03-05
Flight from NYC to BCN at 2023-03-05 12:00 to 19:45
Flight from BCN to SVQ at 2023-03-05 20:35 to 23:15
```

> Trip to BCN or NYC?

For connection flights, I marked segments with the `is_connection` when the time difference is less (or equal) to 24h.

After that, I retrieve the first segment of the trip (after sorting them chronologically), without the `is_connection` flag:

```
Flight from SVQ to BCN at 2023-03-02 06:40 to 09:10 -- connection? = true
Flight from BCN to NYC at 2023-03-02 15:00 to 22:45 -- connection? = false --> Destination (NYC).
Hotel at NYC on 2023-03-02 to 2023-03-05            -- connection? = false
Flight from NYC to BCN at 2023-03-05 12:00 to 19:45 -- connection? = true
Flight from BCN to SVQ at 2023-03-05 20:35 to 23:15 -- connection? = false
```

### Segment.new Hotels and Flight time_to

As we can see in the `input.txt` we have two main types of segments: travels (flight/train) and hotels. The hotel segments don't have times or destination location, and the travel segments don't have arrival date.

That's why when creating a new Segment, I used 00:00 for hotel times, and added the FROM as a TO location as well. For the travels I created a function that adds an extra day if the travel is overnight (if not, it uses the same destination_date).

 With this we can use the sorting algorithm and work with both segment types at the same time.

#### Timezones (known limitation)

The [arrival_time](../lib/travel_manager/time_utils.rb:28) function adds an extra day if the travel is overnight. This can be an issue on DST transition days.

This means that it is possible that overnight flights have incorrect times by 1h. And this could be worse if there is another segment after, losing the possible connection to the trip.

One of the many fixes would imply converting all the hours to UTC (using the local machine timezone), which has no DST transitions. 

### Other rare edge-cases

I tried to make the solution as robust as possible. However, there are endless possibilities (for example, a valid IATA code could be SV1), and there will be cases where the user will get weird outputs, here I list some.

#### Duplicated or not linkeable segements

In case there are duplicated segments in the TXT, the `TripBuilder` will get what it needs to make the user itinerary possible. The only rare case would be that after the process, one or more segments don't get included in the itinerary:

```
Train from SVQ to MAD at 2023-02-15 09:30 to 11:00
Hotel at MAD on 2023-02-15 to 2023-02-17
Train from MAD to SVQ at 2023-02-17 17:00 to 19:30
Flight from MAD to BCN at 2023-03-17 17:00 to 19:30
```

In this case (if the user is based in SVQ), the last segment won't be included in any trips.

#### Multiple reservation for the same travel

```
Train from SVQ to MAD at 2023-02-15 10:30 to 12:00
Hotel at MAD on 2023-02-15 to 2023-02-17
Train from MAD to SVQ at 2023-02-17 18:00 to 20:30
Train from MAD to SVQ at 2023-02-17 17:00 to 19:30
```

In this case, one of the trains for MAD won't be linked. The program will get the first one in the input.txt that matches the conditions. It's not choosing chronologically.

### Exceptions vs Logger

In this library we are using three type of output messages:

- **CLI messages:** basic verbose messages (including CLI argument errors) and the requested output. 
- **Logger:** small issues in the input.txt are reported to the user as warnings, so they can fix them and run the program again. These small issues (such as wrong date format in a SEGMENT) don't stop the program execution, so the user can have all the errors at once. This means that the wrong lines are ignored, which can potentially give a weird output if the errors are not fixed.
- **Exceptions:** if the program's main pipeline cannot continue (file is not readable, every segment is malformed...) it will stop and return an exception with a message for the user.

If the trip only have one segment, and it's malformed, the program will stop and return an exception.

### Parser class responsibilities

The `Parser` class currently have two responsibilities: parsing the lines, and building the segments. This violates the first principle of SOLID, being that a class should only have one responsibility.

However, the building part is encapsulated into a single method that directly calls the Segment constructor. Moving this into a new class for such a small project makes it harder to read (in my opinion).

I think this is very common in this type of projects, where you don't want to add more complexity into a simple architecture like this one. The trade-off is that the Parser class is a bit long, specially with the YARD documentation. 