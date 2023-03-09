describe('Test visit count api', () => {
    it('fetches visitorCounter', () => {
        cy.request('GET', "https://aqz2aoirg0.execute-api.us-east-2.amazonaws.com/dev/visitors/:id")
            .then((resp) => {
                const data = resp.body;

                expect(resp.status).to.eq(200)

                expect(data.count).to.not.be.oneOf([null, "", undefined])
            })
    })
})
