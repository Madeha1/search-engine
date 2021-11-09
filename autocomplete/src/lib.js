Event.observe(window, 'load', function() {
        console.log('test');
        new AutoComplete('q', 'autocomplete.xqy?q=', { delay: 0.1 });
});